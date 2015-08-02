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
      def self.new(attribute, options)
        conditions = compile_conditions(options)
        base_args = [attribute, options, conditions]

        if options[:proc]
          block_exposure = BlockExposure.new(*base_args, &options[:proc])
        else
          delegator_exposure = DelegatorExposure.new(*base_args)
        end

        if options[:using]
          using_class = options[:using]

          if options[:proc]
            RepresentExposure.new(*base_args, using_class, block_exposure)
          else
            RepresentExposure.new(*base_args, using_class, delegator_exposure)
          end

        elsif options[:proc]
          block_exposure

        elsif options[:format_with]
          format_with = options[:format_with]

          if format_with.is_a? Symbol
            FormatterExposure.new(*base_args, format_with)
          elsif format_with.respond_to? :call
            FormatterBlockExposure.new(*base_args, &format_with)
          end

        elsif options[:nesting]
          NestingExposure.new(*base_args)

        else
          delegator_exposure
        end
      end

      def self.compile_conditions(options)
        if_conditions = []
        unless options[:if_extras].nil?
          if_conditions.concat(options[:if_extras])
        end
        if_conditions << options[:if] unless options[:if].nil?

        if_conditions.map! do |cond|
          Condition.new_if cond
        end

        unless_conditions = []
        unless options[:unless_extras].nil?
          unless_conditions.concat(options[:unless_extras])
        end
        unless_conditions << options[:unless] unless options[:unless].nil?

        unless_conditions.map! do |cond|
          Condition.new_unless cond
        end

        if_conditions + unless_conditions
      end
    end
  end
end
