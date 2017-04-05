# frozen_string_literal: true

module Grape
  class Entity
    module Delegator
      class HashObject < Base
        def delegate(attribute)
          object[attribute]
        end
      end
    end
  end
end
