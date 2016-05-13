require 'spec_helper'

describe Grape::Entity::Hash do
  let(:fresh_class) { Class.new(Grape::Entity) }

  it 'Test' do
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

    entity = { post: '123456', 
               city: 'city', 
               street: 'street', 
               house: 'house',
               something_else: 'something_else' } 

    expect(Address.represent(entity).serializable_hash).to eq entity.slice(:city, :street, :house)
    expect(Address.represent(entity, full: true).serializable_hash).to eq entity.slice(:post, :city, :street, :house)

    company = { full_name: 'full_name',
                name: 'name',
                address: entity.clone }

    expect(Company.represent(company).serializable_hash).to eq company.slice(:name).merge(address: entity.slice(:city, :street, :house))
    expect(Company.represent(company, full: true).serializable_hash).to eq company.slice(:full_name, :name).merge(address: entity.slice(:city, :street, :house))
  end  
end
