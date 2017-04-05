# frozen_string_literal: true

require 'spec_helper'

describe Grape::Entity do
  it 'except option for nested entity' do
    module EntitySpec
      class Address < Grape::Entity
        expose :post, if: :full
        expose :city
        expose :street
        expose :house
      end

      class Company < Grape::Entity
        expose :full_name, if: :full
        expose :name
        expose :address do |c, o|
          Address.represent c[:address], Grape::Entity::Options.new(o.opts_hash.except(:full))
        end
      end
    end

    company = {
      full_name: 'full_name',
      name: 'name',
      address: {
        post: '123456',
        city: 'city',
        street: 'street',
        house: 'house',
        something_else: 'something_else'
      }
    }

    expect(EntitySpec::Company.represent(company).serializable_hash).to eq \
      company.slice(:name).merge(address: company[:address].slice(:city, :street, :house))

    expect(EntitySpec::Company.represent(company, full: true).serializable_hash).to eq \
      company.slice(:full_name, :name).merge(address: company[:address].slice(:city, :street, :house))
  end
end
