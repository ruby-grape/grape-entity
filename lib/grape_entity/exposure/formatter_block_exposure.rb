# frozen_string_literal: true

module Grape
  class Entity
    module Exposure
      class FormatterBlockExposure < Base
        attr_reader :format_with

        def setup(&format_with)
          @format_with = format_with
        end

        def dup
          super(&@format_with)
        end

        def ==(other)
          super && @format_with == other.format_with
        end

        def value(entity, _options)
          entity.exec_with_attribute(attribute, &@format_with)
        end
      end
    end
  end
end
