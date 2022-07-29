# frozen_string_literal: true

module Grape
  class Entity
    module Delegator
      class FetchableObject < Base
        def delegate(attribute)
          object.fetch attribute
        end
      end
    end
  end
end
