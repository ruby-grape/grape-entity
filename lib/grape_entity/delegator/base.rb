module Grape
  class Entity
    module Delegator
      class Base
        attr_reader :object

        def initialize(object)
          @object = object
        end

        def delegatable?(_attribute)
          true
        end
      end
    end
  end
end
