# frozen_string_literal: true

module Grape
  class Entity
    Json = defined?(::MultiJson) ? ::MultiJson : ::JSON
  end
end
