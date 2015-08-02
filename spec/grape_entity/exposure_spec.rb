require 'spec_helper'

describe Grape::Entity::Exposure do
  let(:fresh_class) { Class.new(Grape::Entity) }
  let(:model) { double(attributes) }
  let(:attributes) do
    {
      name: 'Bob Bobson',
      email: 'bob@example.com',
      birthday: Time.gm(2012, 2, 27),
      fantasies: ['Unicorns', 'Double Rainbows', 'Nessy'],
      characteristics: [
        { key: 'hair_color', value: 'brown' }
      ],
      friends: [
        double(name: 'Friend 1', email: 'friend1@example.com', characteristics: [], fantasies: [], birthday: Time.gm(2012, 2, 27), friends: []),
        double(name: 'Friend 2', email: 'friend2@example.com', characteristics: [], fantasies: [], birthday: Time.gm(2012, 2, 27), friends: [])
      ]
    }
  end
  let(:entity) { fresh_class.new(model) }
  subject { fresh_class.find_exposure(:name) }

  describe '#key' do
    it 'returns the attribute if no :as is set' do
      fresh_class.expose :name
      expect(subject.key).to eq :name
    end

    it 'returns the :as alias if one exists' do
      fresh_class.expose :name, as: :nombre
      expect(subject.key).to eq :nombre
    end
  end

  describe '#conditions_met?' do
    it 'only passes through hash :if exposure if all attributes match' do
      fresh_class.expose :name, if: { condition1: true, condition2: true }

      expect(subject.conditions_met?(entity, {})).to be false
      expect(subject.conditions_met?(entity, condition1: true)).to be false
      expect(subject.conditions_met?(entity, condition1: true, condition2: true)).to be true
      expect(subject.conditions_met?(entity, condition1: false, condition2: true)).to be false
      expect(subject.conditions_met?(entity, condition1: true, condition2: true, other: true)).to be true
    end

    it 'looks for presence/truthiness if a symbol is passed' do
      fresh_class.expose :name, if: :condition1

      expect(subject.conditions_met?(entity, {})).to be false
      expect(subject.conditions_met?(entity, condition1: true)).to be true
      expect(subject.conditions_met?(entity, condition1: false)).to be false
      expect(subject.conditions_met?(entity, condition1: nil)).to be false
    end

    it 'looks for absence/falsiness if a symbol is passed' do
      fresh_class.expose :name, unless: :condition1

      expect(subject.conditions_met?(entity, {})).to be true
      expect(subject.conditions_met?(entity, condition1: true)).to be false
      expect(subject.conditions_met?(entity, condition1: false)).to be true
      expect(subject.conditions_met?(entity, condition1: nil)).to be true
    end

    it 'only passes through proc :if exposure if it returns truthy value' do
      fresh_class.expose :name, if: ->(_, opts) { opts[:true] }

      expect(subject.conditions_met?(entity, true: false)).to be false
      expect(subject.conditions_met?(entity, true: true)).to be true
    end

    it 'only passes through hash :unless exposure if any attributes do not match' do
      fresh_class.expose :name, unless: { condition1: true, condition2: true }

      expect(subject.conditions_met?(entity, {})).to be true
      expect(subject.conditions_met?(entity, condition1: true)).to be true
      expect(subject.conditions_met?(entity, condition1: true, condition2: true)).to be false
      expect(subject.conditions_met?(entity, condition1: false, condition2: true)).to be true
      expect(subject.conditions_met?(entity, condition1: true, condition2: true, other: true)).to be false
      expect(subject.conditions_met?(entity, condition1: false, condition2: false)).to be true
    end

    it 'only passes through proc :unless exposure if it returns falsy value' do
      fresh_class.expose :name, unless: ->(_, opts) { opts[:true] == true }

      expect(subject.conditions_met?(entity, true: false)).to be true
      expect(subject.conditions_met?(entity, true: true)).to be false
    end
  end
end
