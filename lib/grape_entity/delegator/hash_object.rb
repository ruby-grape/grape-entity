module Grape
  class Entity
    module Delegator
      class HashObject < Base
        def delegate(attribute)
          object[attribute]
        end

        def delegatable?(attribute)
          object.key? attribute
        end
      end
    end
  end
end
