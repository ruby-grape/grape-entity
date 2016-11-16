module Grape
  class Entity
    module Exposure
      class Base
        attr_reader :attribute, :key, :is_safe, :documentation, :conditions, :for_merge

        def self.new(attribute, options, conditions, *args, &block)
          super(attribute, options, conditions).tap { |e| e.setup(*args, &block) }
        end

        def initialize(attribute, options, conditions)
          @attribute = attribute.try(:to_sym)
          @options = options
          @key = (options[:as] || attribute).try(:to_sym)
          @is_safe = options[:safe]
          @for_merge = options[:merge]
          @attr_path_proc = options[:attr_path]
          @documentation = options[:documentation]
          @conditions = conditions
        end

        def dup(&block)
          self.class.new(*dup_args, &block)
        end

        def dup_args
          [@attribute, @options, @conditions.map(&:dup)]
        end

        def ==(other)
          self.class == other.class &&
            @attribute == other.attribute &&
            @options == other.options &&
            @conditions == other.conditions
        end

        def setup
        end

        def nesting?
          false
        end

        # if we have any nesting exposures with the same name.
        def deep_complex_nesting?
          false
        end

        def valid?(entity)
          is_delegatable = entity.delegator.delegatable?(@attribute) || entity.respond_to?(@attribute, true)
          if @is_safe
            is_delegatable
          else
            is_delegatable || raise(NoMethodError, "#{entity.class.name} missing attribute `#{@attribute}' on #{entity.object}")
          end
        end

        def value(_entity, _options)
          raise NotImplementedError
        end

        def serializable_value(entity, options)
          partial_output = valid_value(entity, options)

          if partial_output.respond_to?(:serializable_hash)
            partial_output.serializable_hash
          elsif partial_output.is_a?(Array) && partial_output.all? { |o| o.respond_to?(:serializable_hash) }
            partial_output.map(&:serializable_hash)
          elsif partial_output.is_a?(Hash)
            partial_output.each do |key, value|
              partial_output[key] = value.serializable_hash if value.respond_to?(:serializable_hash)
            end
          else
            partial_output
          end
        end

        def valid_value(entity, options)
          value(entity, options) if valid?(entity)
        end

        def should_return_key?(options)
          options.should_return_key?(@key)
        end

        def conditional?
          !@conditions.empty?
        end

        def conditions_met?(entity, options)
          @conditions.all? { |condition| condition.met? entity, options }
        end

        def should_expose?(entity, options)
          should_return_key?(options) && conditions_met?(entity, options)
        end

        def attr_path(entity, options)
          if @attr_path_proc
            entity.exec_with_object(options, &@attr_path_proc)
          else
            @key
          end
        end

        def with_attr_path(entity, options)
          path_part = attr_path(entity, options)
          options.with_attr_path(path_part) do
            yield
          end
        end

        protected

        attr_reader :options
      end
    end
  end
end
