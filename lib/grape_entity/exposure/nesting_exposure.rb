# frozen_string_literal: true

module Grape
  class Entity
    module Exposure
      class NestingExposure < Base
        attr_reader :nested_exposures

        def setup(nested_exposures = [])
          @nested_exposures = NestedExposures.new(nested_exposures)
        end

        def dup_args
          [*super, @nested_exposures.map(&:dup)]
        end

        def ==(other)
          super && @nested_exposures == other.nested_exposures
        end

        def nesting?
          true
        end

        def find_nested_exposure(attribute)
          nested_exposures.find_by(attribute)
        end

        def valid?(entity)
          nested_exposures.all? { |e| e.valid?(entity) }
        end

        def value(entity, options)
          map_entity_exposures(entity, options) do |exposure, nested_options|
            exposure.value(entity, nested_options)
          end
        end

        def serializable_value(entity, options)
          map_entity_exposures(entity, options) do |exposure, nested_options|
            exposure.serializable_value(entity, nested_options)
          end
        end

        def valid_value_for(key, entity, options)
          new_options = nesting_options_for(options)

          key_exposures = normalized_exposures(entity, new_options).select { |e| e.key(entity) == key }

          key_exposures.map do |exposure|
            exposure.with_attr_path(entity, new_options) do
              exposure.valid_value(entity, new_options)
            end
          end.last
        end

        # if we have any nesting exposures with the same name.
        # delegate :deep_complex_nesting?(entity), to: :nested_exposures
        def deep_complex_nesting?(entity)
          nested_exposures.deep_complex_nesting?(entity)
        end

        private

        def nesting_options_for(options)
          if @key
            options.for_nesting(@key)
          else
            options
          end
        end

        def easy_normalized_exposures(entity, options)
          nested_exposures.select do |exposure|
            exposure.with_attr_path(entity, options) do
              exposure.should_expose?(entity, options)
            end
          end
        end

        # This method 'merges' subsequent nesting exposures with the same name if it's needed
        def normalized_exposures(entity, options)
          return easy_normalized_exposures(entity, options) unless deep_complex_nesting?(entity) # optimization

          table = nested_exposures.each_with_object({}) do |exposure, output|
            should_expose = exposure.with_attr_path(entity, options) do
              exposure.should_expose?(entity, options)
            end
            next unless should_expose
            output[exposure.key(entity)] ||= []
            output[exposure.key(entity)] << exposure
          end
          table.map do |key, exposures|
            last_exposure = exposures.last

            if last_exposure.nesting?
              # For the given key if the last candidates for exposing are nesting then combine them.
              nesting_tail = []
              exposures.reverse_each do |exposure|
                nesting_tail.unshift exposure if exposure.nesting?
              end
              new_nested_exposures = nesting_tail.flat_map(&:nested_exposures)
              NestingExposure.new(key, {}, [], new_nested_exposures).tap do |new_exposure|
                if nesting_tail.any? { |exposure| exposure.deep_complex_nesting?(entity) }
                  new_exposure.instance_variable_set(:@deep_complex_nesting, true)
                end
              end
            else
              last_exposure
            end
          end
        end

        def map_entity_exposures(entity, options)
          new_options = nesting_options_for(options)
          output = OutputBuilder.new(entity)

          normalized_exposures(entity, new_options).each_with_object(output) do |exposure, out|
            exposure.with_attr_path(entity, new_options) do
              result = yield(exposure, new_options)
              out.add(exposure, result)
            end
          end
        end
      end
    end
  end
end

require 'grape_entity/exposure/nesting_exposure/nested_exposures'
require 'grape_entity/exposure/nesting_exposure/output_builder'
