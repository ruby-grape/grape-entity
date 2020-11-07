# frozen_string_literal: true

module Grape
  class Entity
    class Deprecated < StandardError
      def initialize(msg, spec)
        message = "DEPRECATED #{spec}: #{msg}"

        super(message)
      end
    end
  end
end
