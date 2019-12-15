# frozen_string_literal: true

module Grape
  class Entity
    module Delegator
      class HashObject < Base
        def delegate(attribute, hash_access: :to_sym)
          object[attribute.send(hash_access)]
        end
      end
    end
  end
end
