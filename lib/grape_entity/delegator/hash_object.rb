module Grape
  class Entity
    module Delegator
      class HashObject < Base
        def delegate(attribute)
          object[attribute] || object[attribute.to_s]
        end
      end
    end
  end
end
