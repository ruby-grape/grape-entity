# frozen_string_literal: true

module Grape
  class Entity
    module Exposure
      class NestingExposure
        class OutputBuilder < SimpleDelegator
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

          def kind_of?(klass)
            klass == output.class || super
          end
          alias is_a? kind_of?

          def __getobj__
            output
          end

          private

          # If output_collection contains at least one element we have to represent the output as a collection
          def output
            if @output_collection.empty?
              output = @output_hash
            else
              output = @output_collection
              output << @output_hash unless @output_hash.empty?
              output.flatten!
            end
            output
          end

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
