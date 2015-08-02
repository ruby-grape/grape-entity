module Grape
  class Entity
    module Condition
      class BlockCondition < Base
        attr_reader :block

        def setup(&block)
          @block = block
        end

        def ==(other)
          super && @block == other.block
        end

        def if_value(entity, options)
          entity.exec_with_object(options, &@block)
        end
      end
    end
  end
end
