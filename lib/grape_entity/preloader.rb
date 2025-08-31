# frozen_string_literal: true

module Grape
  class Entity
    class Preloader
      attr_reader :entity_class, :objects, :options

      def initialize(entity_class, objects, options)
        @entity_class = entity_class
        @objects = Array.wrap(objects)
        @options = options
      end

      if defined?(ActiveRecord) && ActiveRecord.respond_to?(:version) && ActiveRecord.version >= Gem::Version.new('7.0')
        def call
          associations = {}
          collect_associations(entity_class.root_exposures, associations, options)
          ActiveRecord::Associations::Preloader.new(records: objects, associations: associations).call
        end
      else
        def call
          warn 'The Preloader work normally requires activerecord(>= 7.0) gem'
        end
      end

      private

      def collect_associations(exposures, associations, options)
        exposures.each do |exposure|
          next unless exposure.should_return_key?(options)

          new_associations = associations[exposure.preload] ||= {} if exposure.preload?
          next if exposure.proc_key?

          if exposure.is_a?(Exposure::NestingExposure)
            collect_associations(exposure.nested_exposures, associations, subexposure_options_for(exposure, options))
          elsif exposure.is_a?(Exposure::RepresentExposure) && new_associations
            collect_associations(exposure.using_class.root_exposures, new_associations, subexposure_options_for(exposure, options)) # rubocop:disable Layout/LineLength
          end
        end
      end

      def subexposure_options_for(exposure, options)
        options.for_nesting(exposure.instance_variable_get(:@key))
      end
    end
  end
end
