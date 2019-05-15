# frozen_string_literal: true

require 'pry'

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
