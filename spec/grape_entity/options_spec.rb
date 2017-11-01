# frozen_string_literal: true

require 'spec_helper'

describe Grape::Entity::Options do
  module EntitySpec
    class Crystalline
      attr_accessor :prop1, :prop2, :prop3

      def initialize
        @prop1 = 'value1'
        @prop2 = 'value2'
        @prop3 = 'value3'
      end
    end

    class CrystallineEntity < Grape::Entity
      expose :prop1, if: ->(_, options) { options.fetch(:signal) }
      expose :prop2, if: ->(_, options) { options.fetch(:beam, 'destructive') == 'destructive' }
    end
  end

  context '#fetch' do
    it 'without passing in a required option raises KeyError' do
      expect { EntitySpec::CrystallineEntity.represent(EntitySpec::Crystalline.new).as_json }.to raise_error KeyError
    end

    it 'passing in a required option will expose the values' do
      crystalline_entity = EntitySpec::CrystallineEntity.represent(EntitySpec::Crystalline.new, signal: true)
      expect(crystalline_entity.as_json).to eq(prop1: 'value1', prop2: 'value2')
    end

    it 'with an option that is not default will not expose that value' do
      crystalline_entity = EntitySpec::CrystallineEntity.represent(EntitySpec::Crystalline.new, signal: true, beam: 'intermittent')
      expect(crystalline_entity.as_json).to eq(prop1: 'value1')
    end
  end

  context '#dig', skip: !{}.respond_to?(:dig) do
    let(:model_class) do
      Class.new do
        attr_accessor :prop1

        def initialize
          @prop1 = 'value1'
        end
      end
    end

    let(:entity_class) do
      Class.new(Grape::Entity) do
        expose :prop1, if: ->(_, options) { options.dig(:first, :second) == :nested }
      end
    end

    it 'without passing in a expected option hide the value' do
      entity = entity_class.represent(model_class.new, first: { invalid: :nested })
      expect(entity.as_json).to eq({})
    end

    it 'passing in a expected option will expose the values' do
      entity = entity_class.represent(model_class.new, first: { second: :nested })
      expect(entity.as_json).to eq(prop1: 'value1')
    end
  end
end
