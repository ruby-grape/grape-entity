module Grape
  class Entity
    module Exposure
      class DelegatorExposure < Base
        def value(entity, _options)
          entity.delegate_attribute(attribute)
        end
      end
    end
  end
end
