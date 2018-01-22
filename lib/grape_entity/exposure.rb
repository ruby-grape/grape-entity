# frozen_string_literal: true

require 'grape_entity/exposure/base'
require 'grape_entity/exposure/represent_exposure'
require 'grape_entity/exposure/block_exposure'
require 'grape_entity/exposure/delegator_exposure'
require 'grape_entity/exposure/formatter_exposure'
require 'grape_entity/exposure/formatter_block_exposure'
require 'grape_entity/exposure/nesting_exposure'
require 'grape_entity/condition'

module Grape
  class Entity
    module Exposure
      class << self
        def new(attribute, options)
          conditions = compile_conditions(attribute, options)
          base_args = [attribute, options, conditions]

          passed_proc = options[:proc]
          using_class = options[:using]
          format_with = options[:format_with]

          if using_class
            build_class_exposure(base_args, using_class, passed_proc)
          elsif passed_proc
            build_block_exposure(base_args, passed_proc)
          elsif format_with
            build_formatter_exposure(base_args, format_with)
          elsif options[:nesting]
            build_nesting_exposure(base_args)
          else
            build_delegator_exposure(base_args)
          end
        end

        private

        def compile_conditions(attribute, options)
          if_conditions = [
            options[:if_extras],
            options[:if]
          ].compact.flatten.map { |cond| Condition.new_if(cond) }

          unless_conditions = [
            options[:unless_extras],
            options[:unless]
          ].compact.flatten.map { |cond| Condition.new_unless(cond) }

          unless_conditions << expose_nil_condition(attribute) if options[:expose_nil] == false

          if_conditions + unless_conditions
        end

        def expose_nil_condition(attribute)
          Condition.new_unless(
            proc { |object, _options| Delegator.new(object).delegate(attribute).nil? }
          )
        end

        def build_class_exposure(base_args, using_class, passed_proc)
          exposure =
            if passed_proc
              build_block_exposure(base_args, passed_proc)
            else
              build_delegator_exposure(base_args)
            end

          RepresentExposure.new(*base_args, using_class, exposure)
        end

        def build_formatter_exposure(base_args, format_with)
          if format_with.is_a? Symbol
            FormatterExposure.new(*base_args, format_with)
          elsif format_with.respond_to?(:call)
            FormatterBlockExposure.new(*base_args, &format_with)
          end
        end

        def build_nesting_exposure(base_args)
          NestingExposure.new(*base_args)
        end

        def build_block_exposure(base_args, passed_proc)
          BlockExposure.new(*base_args, &passed_proc)
        end

        def build_delegator_exposure(base_args)
          DelegatorExposure.new(*base_args)
        end
      end
    end
  end
end
