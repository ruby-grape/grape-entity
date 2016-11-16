module Grape
  class Entity
    module Condition
      class Base
        def self.new(inverse, *args, &block)
          super(inverse).tap { |e| e.setup(*args, &block) }
        end

        def initialize(inverse = false)
          @inverse = inverse
        end

        def ==(other)
          (self.class == other.class) && (inversed? == other.inversed?)
        end

        def inversed?
          @inverse
        end

        def met?(entity, options)
          !@inverse ? if_value(entity, options) : unless_value(entity, options)
        end

        def if_value(_entity, _options)
          raise NotImplementedError
        end

        def unless_value(entity, options)
          !if_value(entity, options)
        end
      end
    end
  end
end
