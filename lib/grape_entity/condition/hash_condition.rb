# frozen_string_literal: true

module Grape
  class Entity
    module Condition
      class HashCondition < Base
        attr_reader :cond_hash

        def setup(cond_hash)
          @cond_hash = cond_hash
        end

        def ==(other)
          super && @cond_hash == other.cond_hash
        end

        def if_value(_entity, options)
          @cond_hash.all? { |k, v| options[k.to_sym] == v }
        end

        def unless_value(_entity, options)
          @cond_hash.any? { |k, v| options[k.to_sym] != v }
        end
      end
    end
  end
end
