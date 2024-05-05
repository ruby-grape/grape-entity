# frozen_string_literal: true

module Grape
  class Entity
    if defined?(::MultiJson)
      Json = ::MultiJson
    else
      Json = ::JSON
      Json::ParseError = Json::ParserError
    end
  end
end
