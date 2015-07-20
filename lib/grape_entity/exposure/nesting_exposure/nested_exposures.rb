module Grape
  class Entity
    module Exposure
      class NestingExposure
        class NestedExposures
          include Enumerable

          def initialize(exposures)
            @exposures = exposures
          end

          def find_by(attribute)
            @exposures.find { |e| e.attribute == attribute }
          end

          def <<(exposure)
            reset_memoization!
            @exposures << exposure
          end

          def delete_by(*attributes)
            reset_memoization!
            @exposures.reject! { |e| e.attribute.in? attributes }
          end

          def clear
            reset_memoization!
            @exposures.clear
          end

          delegate :each,
                   :to_ary, :to_a,
                   :[],
                   :==,
                   :size,
                   :count,
                   :length,
                   :empty?,
                   to: :@exposures

          # Determine if we have any nesting exposures with the same name.
          def deep_complex_nesting?
            if @deep_complex_nesting.nil?
              all_nesting = select(&:nesting?)
              @deep_complex_nesting = all_nesting.group_by(&:key).any? { |_key, exposures| exposures.many? }
            else
              @deep_complex_nesting
            end
          end

          private

          def reset_memoization!
            @deep_complex_nesting = nil
          end
        end
      end
    end
  end
end
