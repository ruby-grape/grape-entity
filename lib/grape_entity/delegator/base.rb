# frozen_string_literal: true

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

        def accepts_options?
          # Why not `arity > 1`? It might be negative https://ruby-doc.org/core-2.6.6/Method.html#method-i-arity
          method(:delegate).arity != 1
        end
      end
    end
  end
end
