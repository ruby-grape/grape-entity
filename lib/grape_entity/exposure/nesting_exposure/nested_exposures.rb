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
            @exposures.reject! { |e| attributes.include? e.attribute }
            @exposures
          end

          def clear
            reset_memoization!
            @exposures.clear
          end

          [
            :each,
            :to_ary, :to_a,
            :all?,
            :select,
            :each_with_object,
            :[],
            :==,
            :size,
            :count,
            :length,
            :empty?
          ].each do |name|
            class_eval <<-RUBY, __FILE__, __LINE__
              def #{name}(*args, &block)
                @exposures.#{name}(*args, &block)
              end
            RUBY
          end

          # Determine if we have any nesting exposures with the same name.
          def deep_complex_nesting?
            if @deep_complex_nesting.nil?
              all_nesting = select(&:nesting?)
              @deep_complex_nesting = all_nesting.group_by(&:key).any? { |_key, exposures| exposures.length > 1 }
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
