# frozen_string_literal: true

module Grape
  class Entity
    module Exposure
      class NestingExposure
        class NestedExposures
          include Enumerable

          def initialize(exposures)
            @exposures = exposures
            @deep_complex_nesting = nil
          end

          def find_by(attribute)
            @exposures.find { |e| e.attribute == attribute }
          end

          def select_by(attribute)
            @exposures.select { |e| e.attribute == attribute }
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

          %i[
            each
            to_ary to_a
            all?
            select
            each_with_object
            \[\]
            ==
            size
            count
            length
            empty?
          ].each do |name|
            class_eval <<-RUBY, __FILE__, __LINE__
              def #{name}(*args, &block)
                @exposures.#{name}(*args, &block)
              end
            RUBY
          end

          # Determine if we have any nesting exposures with the same name.
          def deep_complex_nesting?(entity)
            if @deep_complex_nesting.nil?
              all_nesting = select(&:nesting?)
              @deep_complex_nesting =
                all_nesting
                .group_by { |exposure| exposure.key(entity) }
                .any? { |_key, exposures| exposures.length > 1 }
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
