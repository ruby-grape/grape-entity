# frozen_string_literal: true

module Grape
  class Entity
    module Delegator
      class PlainObject < Base
        def delegate(attribute)
          object.send attribute
        end

        def delegatable?(attribute)
          object.respond_to? attribute, true
        end
      end
    end
  end
end
