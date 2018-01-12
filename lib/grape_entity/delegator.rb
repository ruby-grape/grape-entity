# frozen_string_literal: true

require 'grape_entity/delegator/base'
require 'grape_entity/delegator/hash_object'
require 'grape_entity/delegator/openstruct_object'
require 'grape_entity/delegator/fetchable_object'
require 'grape_entity/delegator/plain_object'

module Grape
  class Entity
    module Delegator
      def self.new(object)
        delegator_klass =
          if object.is_a?(Hash) then HashObject
          elsif defined?(OpenStruct) && object.is_a?(OpenStruct) then OpenStructObject
          elsif object.respond_to?(:fetch, true) then FetchableObject
          else PlainObject
          end

        delegator_klass.new(object)
      end
    end
  end
end
