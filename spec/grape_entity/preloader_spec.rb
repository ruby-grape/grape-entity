# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Grape::Entity::Preloader do
  class SQLCounter
    class << self
      attr_accessor :ignored_sql, :log, :log_all

      def clear_log
        self.log = []
        self.log_all = []
      end
    end
    clear_log

    def call(_name, _start, _finish, _message_id, values)
      return if values[:cached]

      sql = values[:sql]
      self.class.log_all << sql
      self.class.log << sql unless %w[SCHEMA TRANSACTION].include? values[:name]
    end

    ActiveSupport::Notifications.subscribe('sql.active_record', new)
  end

  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end

  class Tag < ApplicationRecord
    include Grape::Entity::DSL

    connection.create_table(:tags) do |t|
      t.string :name
      t.references :target, polymorphic: true
    end

    belongs_to :target, polymorphic: true

    entity do
      expose :name
    end
  end

  class Book < ApplicationRecord
    include Grape::Entity::DSL

    connection.create_table(:books) do |t|
      t.string :name
      t.references :author
    end

    belongs_to :author, foreign_key: :author_id, class_name: 'User'
    has_many :tags, as: :target, dependent: :destroy

    entity do
      expose :name
      expose :tags, using: Tag::Entity, preload: :tags
    end
  end

  class User < ApplicationRecord
    include Grape::Entity::DSL

    connection.create_table(:users) do |t|
      t.string :name
    end

    has_many :books, foreign_key: :author_id, dependent: :destroy
    has_many :tags, as: :target, dependent: :destroy

    entity do
      expose :name
      expose :books, using: Book::Entity, preload: :books
      expose :tags, using: Tag::Entity, preload: :tags
    end
  end

  let!(:users) { [User.create(name: 'User1'), User.create(name: 'User2')] }
  let!(:user_tags) { [Tag.create(name: 'Tag1', target: users[0]), Tag.create(name: 'Tag2', target: users[1])] }
  let!(:books) { [Book.create(name: 'Book1', author: users[0]), Book.create(name: 'Book2', author: users[1])] }
  let!(:book_tags) { [Tag.create(name: 'Tag1', target: books[0]), Tag.create(name: 'Tag2', target: books[1])] }

  before { SQLCounter.clear_log }

  it 'preload associations through RepresentExposure' do
    User::Entity.preload_and_represent(users)

    expect(SQLCounter.log).to eq([
                                   'SELECT "books".* FROM "books" WHERE "books"."author_id" IN (?, ?)',
                                   'SELECT "tags".* FROM "tags" WHERE "tags"."target_type" = ? AND "tags"."target_id" IN (?, ?)',
                                   'SELECT "tags".* FROM "tags" WHERE "tags"."target_type" = ? AND "tags"."target_id" IN (?, ?)'
                                 ])
  end

  it 'preload associations through NestingExposure' do
    Class.new(User::Entity) do
      unexpose :books
      expose :nesting do
        expose :books, using: Book::Entity, preload: :books
      end
    end.preload_and_represent(users)

    expect(SQLCounter.log).to eq([
                                   'SELECT "books".* FROM "books" WHERE "books"."author_id" IN (?, ?)',
                                   'SELECT "tags".* FROM "tags" WHERE "tags"."target_type" = ? AND "tags"."target_id" IN (?, ?)',
                                   'SELECT "tags".* FROM "tags" WHERE "tags"."target_type" = ? AND "tags"."target_id" IN (?, ?)'
                                 ])
  end

  it 'preload same associations multiple times' do
    Class.new(User::Entity) do
      expose(:other_books, preload: :books) { :other_books }
    end.preload_and_represent(users)

    expect(SQLCounter.log).to eq([
                                   'SELECT "books".* FROM "books" WHERE "books"."author_id" IN (?, ?)',
                                   'SELECT "tags".* FROM "tags" WHERE "tags"."target_type" = ? AND "tags"."target_id" IN (?, ?)',
                                   'SELECT "tags".* FROM "tags" WHERE "tags"."target_type" = ? AND "tags"."target_id" IN (?, ?)'
                                 ])
  end

  describe 'only preload associations that are specified in the options' do
    it 'through :only option' do
      User::Entity.preload_and_represent(users, only: [:tags])

      expect(SQLCounter.log).to eq([
                                     'SELECT "tags".* FROM "tags" WHERE "tags"."target_type" = ? AND "tags"."target_id" IN (?, ?)'
                                   ])
    end

    it 'through :except option' do
      User::Entity.preload_and_represent(users, except: [:tags])

      expect(SQLCounter.log).to eq([
                                     'SELECT "books".* FROM "books" WHERE "books"."author_id" IN (?, ?)',
                                     'SELECT "tags".* FROM "tags" WHERE "tags"."target_type" = ? AND "tags"."target_id" IN (?, ?)'
                                   ])
    end
  end
end
