require 'grape_entity/condition/base'
require 'grape_entity/condition/block_condition'
require 'grape_entity/condition/hash_condition'
require 'grape_entity/condition/symbol_condition'

module Grape
  class Entity
    module Condition
      def self.new_if(arg)
        case arg
        when Hash then HashCondition.new false, arg
        when Proc then BlockCondition.new false, &arg
        when Symbol then SymbolCondition.new false, arg
        end
      end

      def self.new_unless(arg)
        case arg
        when Hash then HashCondition.new true, arg
        when Proc then BlockCondition.new true, &arg
        when Symbol then SymbolCondition.new true, arg
        end
      end
    end
  end
end
