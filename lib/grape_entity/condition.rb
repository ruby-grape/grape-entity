# frozen_string_literal: true

require 'grape_entity/condition/base'
require 'grape_entity/condition/block_condition'
require 'grape_entity/condition/hash_condition'
require 'grape_entity/condition/symbol_condition'

module Grape
  class Entity
    module Condition
      class << self
        def new_if(arg)
          condition(false, arg)
        end

        def new_unless(arg)
          condition(true, arg)
        end

        private

        def condition(inverse, arg)
          condition_klass =
            case arg
            when Hash then HashCondition
            when Proc then BlockCondition
            when Symbol then SymbolCondition
            end

          condition_klass.new(inverse, arg)
        end
      end
    end
  end
end
