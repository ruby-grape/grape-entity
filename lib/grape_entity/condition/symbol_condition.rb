module Grape
  class Entity
    module Condition
      class SymbolCondition < Base
        attr_reader :symbol

        def setup(symbol)
          @symbol = symbol
        end

        def ==(other)
          super && @symbol == other.symbol
        end

        def if_value(_entity, options)
          options[symbol]
        end
      end
    end
  end
end
