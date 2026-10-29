# frozen_string_literal: true

module Grape
  class Entity
    module Exposure
      class NestingExposure
        class OutputBuilder
          def initialize(entity)
            @entity = entity
            @output_hash = {}
            @output_collection = []
          end

          def add(exposure, result)
            # Save a result array in collections' array if it should be merged
            if result.is_a?(Array) && exposure.for_merge
              @output_collection << result
            elsif exposure.for_merge
              # If we have an array which should not be merged - save it with a key as a hash
              # If we have hash which should be merged - save it without a key (merge)
              return unless result

              @output_hash.merge! result, &merge_strategy(exposure.for_merge)
            else
              @output_hash[exposure.key(@entity)] = result
            end
          end

          # If output_collection contains at least one element we have to represent the output as a collection
          def output
            return @output_hash if @output_collection.empty?

            result = @output_collection.dup
            result << @output_hash unless @output_hash.empty?
            result.flatten
          end

          private

          # In case if we want to solve collisions providing lambda to :merge option
          def merge_strategy(for_merge)
            if for_merge.respond_to? :call
              for_merge
            else
              -> {}
            end
          end
        end
      end
    end
  end
end
