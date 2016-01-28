module Grape
  class Entity
    module Exposure
      class RepresentExposure < Base
        attr_reader :using_class_name, :subexposure

        def setup(using_class_name, subexposure)
          @using_class = nil
          @using_class_name = using_class_name
          @subexposure = subexposure
        end

        def dup_args
          [*super, using_class_name, subexposure]
        end

        def ==(other)
          super &&
            @using_class_name == other.using_class_name &&
            @subexposure == other.subexposure
        end

        def value(entity, options)
          new_options = options.for_nesting(key)
          using_class.represent(@subexposure.value(entity, options), new_options)
        end

        def valid?(entity)
          @subexposure.valid? entity
        end

        def using_class
          @using_class ||= if @using_class_name.respond_to? :constantize
                             @using_class_name.constantize
                           else
                             @using_class_name
                           end
        end

        private

        def using_options_for(options)
          options.for_nesting(key)
        end
      end
    end
  end
end
