require 'multi_json'
require 'set'

module Grape
  # An Entity is a lightweight structure that allows you to easily
  # represent data from your application in a consistent and abstracted
  # way in your API. Entities can also provide documentation for the
  # fields exposed.
  #
  # @example Entity Definition
  #
  #   module API
  #     module Entities
  #       class User < Grape::Entity
  #         expose :first_name, :last_name, :screen_name, :location
  #         expose :field, documentation: { type: "string", desc: "describe the field" }
  #         expose :latest_status, using: API::Status, as: :status, unless: { collection: true }
  #         expose :email, if: { type: :full }
  #         expose :new_attribute, if: { version: 'v2' }
  #         expose(:name) { |model, options| [model.first_name, model.last_name].join(' ') }
  #       end
  #     end
  #   end
  #
  # Entities are not independent structures, rather, they create
  # **representations** of other Ruby objects using a number of methods
  # that are convenient for use in an API. Once you've defined an Entity,
  # you can use it in your API like this:
  #
  # @example Usage in the API Layer
  #
  #   module API
  #     class Users < Grape::API
  #       version 'v2'
  #
  #       desc 'User index', { params: API::Entities::User.documentation }
  #       get '/users' do
  #         @users = User.all
  #         type = current_user.admin? ? :full : :default
  #         present @users, with: API::Entities::User, type: type
  #       end
  #     end
  #   end
  class Entity
    attr_reader :object, :delegator, :options

    # The Entity DSL allows you to mix entity functionality into
    # your existing classes.
    module DSL
      def self.included(base)
        base.extend ClassMethods
        ancestor_entity_class = base.ancestors.detect { |a| a.entity_class if a.respond_to?(:entity_class) }
        base.const_set(:Entity, Class.new(ancestor_entity_class || Grape::Entity)) unless const_defined?(:Entity)
      end

      module ClassMethods
        # Returns the automatically-created entity class for this
        # Class.
        def entity_class(search_ancestors = true)
          klass = const_get(:Entity) if const_defined?(:Entity)
          klass ||= ancestors.detect { |a| a.entity_class(false) if a.respond_to?(:entity_class) } if search_ancestors
          klass
        end

        # Call this to make exposures to the entity for this Class.
        # Can be called with symbols for the attributes to expose,
        # a block that yields the full Entity DSL (See Grape::Entity),
        # or both.
        #
        # @example Symbols only.
        #
        #   class User
        #     include Grape::Entity::DSL
        #
        #     entity :name, :email
        #   end
        #
        # @example Mixed.
        #
        #   class User
        #     include Grape::Entity::DSL
        #
        #     entity :name, :email do
        #       expose :latest_status, using: Status::Entity, if: :include_status
        #       expose :new_attribute, if: { version: 'v2' }
        #     end
        #   end
        def entity(*exposures, &block)
          entity_class.expose(*exposures) if exposures.any?
          entity_class.class_eval(&block) if block_given?
          entity_class
        end
      end

      # Instantiates an entity version of this object.
      def entity(options = {})
        self.class.entity_class.new(self, options)
      end
    end

    class << self
      # Returns exposures that have been declared for this Entity or
      # ancestors. The keys are symbolized references to methods on the
      # containing object, the values are the options that were passed into expose.
      # @return [Hash] of exposures
      attr_accessor :exposures
      attr_accessor :root_exposures
      # Returns all formatters that are registered for this and it's ancestors
      # @return [Hash] of formatters
      attr_accessor :formatters
      attr_accessor :nested_attribute_names
      attr_accessor :nested_exposures
    end

    @exposures = {}
    @root_exposures = {}
    @nested_exposures = {}
    @nested_attribute_names = {}
    @formatters = {}

    def self.inherited(subclass)
      subclass.exposures = exposures.dup
      subclass.root_exposures = root_exposures.dup
      subclass.nested_exposures = nested_exposures.dup
      subclass.nested_attribute_names = nested_attribute_names.dup
      subclass.formatters = formatters.dup
    end

    # This method is the primary means by which you will declare what attributes
    # should be exposed by the entity.
    #
    # @option options :as Declare an alias for the representation of this attribute.
    # @option options :if When passed a Hash, the attribute will only be exposed if the
    #   runtime options match all the conditions passed in. When passed a lambda, the
    #   lambda will execute with two arguments: the object being represented and the
    #   options passed into the representation call. Return true if you want the attribute
    #   to be exposed.
    # @option options :unless When passed a Hash, the attribute will be exposed if the
    #   runtime options fail to match any of the conditions passed in. If passed a lambda,
    #   it will yield the object being represented and the options passed to the
    #   representation call. Return true to prevent exposure, false to allow it.
    # @option options :using This option allows you to map an attribute to another Grape
    #   Entity. Pass it a Grape::Entity class and the attribute in question will
    #   automatically be transformed into a representation that will receive the same
    #   options as the parent entity when called. Note that arrays are fine here and
    #   will automatically be detected and handled appropriately.
    # @option options :proc If you pass a Proc into this option, it will
    #   be used directly to determine the value for that attribute. It
    #   will be called with the represented object as well as the
    #   runtime options that were passed in. You can also just supply a
    #   block to the expose call to achieve the same effect.
    # @option options :documentation Define documenation for an exposed
    #   field, typically the value is a hash with two fields, type and desc.
    def self.expose(*args, &block)
      options = merge_options(args.last.is_a?(Hash) ? args.pop : {})

      if args.size > 1
        fail ArgumentError, 'You may not use the :as option on multi-attribute exposures.' if options[:as]
        fail ArgumentError, 'You may not use block-setting on multi-attribute exposures.' if block_given?
      end

      fail ArgumentError, 'You may not use block-setting when also using format_with' if block_given? && options[:format_with].respond_to?(:call)

      options[:proc] = block if block_given? && block.parameters.any?

      @nested_attributes ||= []

      # rubocop:disable Style/Next
      args.each do |attribute|
        if @nested_attributes.empty?
          root_exposures[attribute] = options
        else
          orig_attribute = attribute.to_sym
          attribute = "#{@nested_attributes.last}__#{attribute}".to_sym
          nested_attribute_names[attribute] = orig_attribute
          options[:nested] = true
          nested_exposures.deep_merge!(@nested_attributes.last.to_sym  => { attribute => options })
        end

        exposures[attribute] = options

        # Nested exposures are given in a block with no parameters.
        if block_given? && block.parameters.empty?
          @nested_attributes << attribute
          block.call
          @nested_attributes.pop
        end
      end
    end

    def self.unexpose(attribute)
      root_exposures.delete(attribute)
      exposures.delete(attribute)
      nested_exposures.delete(attribute)
      nested_attribute_names.delete(attribute)
    end

    # Set options that will be applied to any exposures declared inside the block.
    #
    # @example Multi-exposure if
    #
    #   class MyEntity < Grape::Entity
    #     with_options if: { awesome: true } do
    #       expose :awesome, :sweet
    #     end
    #   end
    def self.with_options(options)
      (@block_options ||= []).push(valid_options(options))
      yield
      @block_options.pop
    end

    # Returns a hash, the keys are symbolized references to fields in the entity,
    # the values are document keys in the entity's documentation key. When calling
    # #docmentation, any exposure without a documentation key will be ignored.
    def self.documentation
      @documentation ||= exposures.each_with_object({}) do |(attribute, exposure_options), memo|
        if exposure_options[:documentation].present?
          memo[key_for(attribute)] = exposure_options[:documentation]
        end
      end
    end

    # This allows you to declare a Proc in which exposures can be formatted with.
    # It take a block with an arity of 1 which is passed as the value of the exposed attribute.
    #
    # @param name [Symbol] the name of the formatter
    # @param block [Proc] the block that will interpret the exposed attribute
    #
    # @example Formatter declaration
    #
    #   module API
    #     module Entities
    #       class User < Grape::Entity
    #         format_with :timestamp do |date|
    #           date.strftime('%m/%d/%Y')
    #         end
    #
    #         expose :birthday, :last_signed_in, format_with: :timestamp
    #       end
    #     end
    #   end
    #
    # @example Formatters are available to all decendants
    #
    #   Grape::Entity.format_with :timestamp do |date|
    #     date.strftime('%m/%d/%Y')
    #   end
    #
    def self.format_with(name, &block)
      fail ArgumentError, 'You must pass a block for formatters' unless block_given?
      formatters[name.to_sym] = block
    end

    # This allows you to set a root element name for your representation.
    #
    # @param plural   [String] the root key to use when representing
    #   a collection of objects. If missing or nil, no root key will be used
    #   when representing collections of objects.
    # @param singular [String] the root key to use when representing
    #   a single object. If missing or nil, no root key will be used when
    #   representing an individual object.
    #
    # @example Entity Definition
    #
    #   module API
    #     module Entities
    #       class User < Grape::Entity
    #         root 'users', 'user'
    #         expose :id
    #       end
    #     end
    #   end
    #
    # @example Usage in the API Layer
    #
    #   module API
    #     class Users < Grape::API
    #       version 'v2'
    #
    #       # this will render { "users" : [ { "id" : "1" }, { "id" : "2" } ] }
    #       get '/users' do
    #         @users = User.all
    #         present @users, with: API::Entities::User
    #       end
    #
    #       # this will render { "user" : { "id" : "1" } }
    #       get '/users/:id' do
    #         @user = User.find(params[:id])
    #         present @user, with: API::Entities::User
    #       end
    #     end
    #   end
    def self.root(plural, singular = nil)
      @collection_root = plural
      @root = singular
    end

    # This allows you to present a collection of objects.
    #
    # @param present_collection   [true or false] when true all objects will be available as
    #   items in your presenter instead of wrapping each object in an instance of your presenter.
    #  When false (default) every object in a collection to present will be wrapped separately
    #  into an instance of your presenter.
    # @param collection_name [Symbol] the name of the collection accessor in your entity object.
    #  Default :items
    #
    # @example Entity Definition
    #
    #   module API
    #     module Entities
    #       class User < Grape::Entity
    #         expose :id
    #       end
    #
    #       class Users < Grape::Entity
    #         present_collection true
    #         expose :items, as: 'users', using: API::Entities::Users
    #         expose :version, documentation: { type: 'string',
    #                                           desc: 'actual api version',
    #                                           required: true }
    #
    #         def version
    #           options[:version]
    #         end
    #       end
    #     end
    #   end
    #
    # @example Usage in the API Layer
    #
    #   module API
    #     class Users < Grape::API
    #       version 'v2'
    #
    #       # this will render { "users" : [ { "id" : "1" }, { "id" : "2" } ], "version" : "v2" }
    #       get '/users' do
    #         @users = User.all
    #         present @users, with: API::Entities::Users
    #       end
    #
    #       # this will render { "user" : { "id" : "1" } }
    #       get '/users/:id' do
    #         @user = User.find(params[:id])
    #         present @user, with: API::Entities::User
    #       end
    #     end
    #   end
    #
    def self.present_collection(present_collection = false, collection_name = :items)
      @present_collection = present_collection
      @collection_name = collection_name
    end

    # This convenience method allows you to instantiate one or more entities by
    # passing either a singular or collection of objects. Each object will be
    # initialized with the same options. If an array of objects is passed in,
    # an array of entities will be returned. If a single object is passed in,
    # a single entity will be returned.
    #
    # @param objects [Object or Array] One or more objects to be represented.
    # @param options [Hash] Options that will be passed through to each entity
    #   representation.
    #
    # @option options :root [String or false] override the default root name set for the entity.
    #   Pass nil or false to represent the object or objects with no root name
    #   even if one is defined for the entity.
    # @option options :serializable [true or false] when true a serializable Hash will be returned
    #
    # @option options :only [Array] all the fields that should be returned
    # @option options :except [Array] all the fields that should not be returned
    def self.represent(objects, options = {})
      if objects.respond_to?(:to_ary) && ! @present_collection
        root_element =  root_element(:collection_root)
        inner = objects.to_ary.map { |object| new(object, { collection: true }.merge(options)).presented }
      else
        objects = { @collection_name => objects } if @present_collection
        root_element = root_element(:root)
        inner = new(objects, options).presented
      end

      root_element = options[:root] if options.key?(:root)

      root_element ? { root_element => inner } : inner
    end

    # This method returns the entity's root or collection root node, or its parent's
    # @param root_type: either :collection_root or just :root
    def self.root_element(root_type)
      if instance_variable_get("@#{root_type}")
        instance_variable_get("@#{root_type}")
      elsif superclass.respond_to? :root_element
        superclass.root_element(root_type)
      end
    end

    def presented
      if options[:serializable]
        serializable_hash
      else
        self
      end
    end

    def initialize(object, options = {})
      @object = object
      @delegator = Delegator.new object
      @options = options
    end

    def exposures
      self.class.exposures
    end

    def root_exposures
      self.class.root_exposures
    end

    def documentation
      self.class.documentation
    end

    def formatters
      self.class.formatters
    end

    # The serializable hash is the Entity's primary output. It is the transformed
    # hash for the given data model and is used as the basis for serialization to
    # JSON and other formats.
    #
    # @param runtime_options [Hash] Any options you pass in here will be known to the entity
    #   representation, this is where you can trigger things from conditional options
    #   etc.
    def serializable_hash(runtime_options = {})
      return nil if object.nil?

      opts = options.merge(runtime_options || {})

      root_exposures.each_with_object({}) do |(attribute, exposure_options), output|
        next unless should_return_attribute?(attribute, opts) && conditions_met?(exposure_options, opts)

        partial_output = value_for(attribute, opts)

        output[self.class.key_for(attribute)] =
          if partial_output.respond_to?(:serializable_hash)
            partial_output.serializable_hash(runtime_options)
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
    end

    def should_return_attribute?(attribute, options)
      key = self.class.key_for(attribute)
      only = only_fields(options).nil? ||
             only_fields(options).include?(key)
      except = except_fields(options) && except_fields(options).include?(key) &&
               except_fields(options)[key] == true
      only && !except
    end

    def only_fields(options, for_attribute = nil)
      return nil unless options[:only]

      @only_fields ||= options[:only].each_with_object({}) do |attribute, allowed_fields|
        if attribute.is_a?(Hash)
          attribute.each do |attr, nested_attrs|
            allowed_fields[attr] ||= []
            allowed_fields[attr] += nested_attrs
          end
        else
          allowed_fields[attribute] = true
        end
      end.symbolize_keys

      if for_attribute && @only_fields[for_attribute].is_a?(Array)
        @only_fields[for_attribute]
      elsif for_attribute.nil?
        @only_fields
      end
    end

    def except_fields(options, for_attribute = nil)
      return nil unless options[:except]

      @except_fields ||= options[:except].each_with_object({}) do |attribute, allowed_fields|
        if attribute.is_a?(Hash)
          attribute.each do |attr, nested_attrs|
            allowed_fields[attr] ||= []
            allowed_fields[attr] += nested_attrs
          end
        else
          allowed_fields[attribute] = true
        end
      end.symbolize_keys

      if for_attribute && @except_fields[for_attribute].is_a?(Array)
        @except_fields[for_attribute]
      elsif for_attribute.nil?
        @except_fields
      end
    end

    alias_method :as_json, :serializable_hash

    def to_json(options = {})
      options = options.to_h if options && options.respond_to?(:to_h)
      MultiJson.dump(serializable_hash(options))
    end

    def to_xml(options = {})
      options = options.to_h if options && options.respond_to?(:to_h)
      serializable_hash(options).to_xml(options)
    end

    protected

    def self.name_for(attribute)
      attribute = attribute.to_sym
      nested_attribute_names[attribute] || attribute
    end

    def self.key_for(attribute)
      exposures[attribute.to_sym][:as] || name_for(attribute)
    end

    def self.nested_exposures_for?(attribute)
      nested_exposures.key?(attribute)
    end

    def nested_value_for(attribute, options)
      nested_exposures = self.class.nested_exposures[attribute]
      nested_attributes =
        nested_exposures.map do |nested_attribute, nested_exposure_options|
          if conditions_met?(nested_exposure_options, options)
            [self.class.key_for(nested_attribute), value_for(nested_attribute, options)]
          end
        end

      Hash[nested_attributes.compact]
    end

    def value_for(attribute, options = {})
      exposure_options = exposures[attribute.to_sym]
      return unless valid_exposure?(attribute, exposure_options)

      if exposure_options[:using]
        exposure_options[:using] = exposure_options[:using].constantize if exposure_options[:using].respond_to? :constantize

        using_options = options_for_using(attribute, options)

        if exposure_options[:proc]
          exposure_options[:using].represent(instance_exec(object, options, &exposure_options[:proc]), using_options)
        else
          exposure_options[:using].represent(delegate_attribute(attribute), using_options)
        end

      elsif exposure_options[:proc]
        instance_exec(object, options, &exposure_options[:proc])

      elsif exposure_options[:format_with]
        format_with = exposure_options[:format_with]

        if format_with.is_a?(Symbol) && formatters[format_with]
          instance_exec(delegate_attribute(attribute), &formatters[format_with])
        elsif format_with.is_a?(Symbol)
          send(format_with, delegate_attribute(attribute))
        elsif format_with.respond_to? :call
          instance_exec(delegate_attribute(attribute), &format_with)
        end

      elsif self.class.nested_exposures_for?(attribute)
        nested_value_for(attribute, options)
      else
        delegate_attribute(attribute)
      end
    end

    def delegate_attribute(attribute)
      name = self.class.name_for(attribute)
      if respond_to?(name, true)
        send(name)
      else
        delegator.delegate(name)
      end
    end

    def valid_exposure?(attribute, exposure_options)
      if self.class.nested_exposures_for?(attribute)
        self.class.nested_exposures[attribute].all? { |a, o| valid_exposure?(a, o) }
      elsif exposure_options.key?(:proc)
        true
      else
        name = self.class.name_for(attribute)
        is_delegatable = delegator.delegatable?(name) || respond_to?(name, true)
        if exposure_options[:safe]
          is_delegatable
        else
          is_delegatable || fail(NoMethodError, "#{self.class.name} missing attribute `#{name}' on #{object}")
        end
      end
    end

    def conditions_met?(exposure_options, options)
      if_conditions = []
      unless exposure_options[:if_extras].nil?
        if_conditions.concat(exposure_options[:if_extras])
      end
      if_conditions << exposure_options[:if] unless exposure_options[:if].nil?

      if_conditions.each do |if_condition|
        case if_condition
        when Hash then if_condition.each_pair { |k, v| return false if options[k.to_sym] != v }
        when Proc then return false unless instance_exec(object, options, &if_condition)
        when Symbol then return false unless options[if_condition]
        end
      end

      unless_conditions = []
      unless exposure_options[:unless_extras].nil?
        unless_conditions.concat(exposure_options[:unless_extras])
      end
      unless_conditions << exposure_options[:unless] unless exposure_options[:unless].nil?

      unless_conditions.each do |unless_condition|
        case unless_condition
        when Hash then unless_condition.each_pair { |k, v| return false if options[k.to_sym] == v }
        when Proc then return false if instance_exec(object, options, &unless_condition)
        when Symbol then return false if options[unless_condition]
        end
      end

      true
    end

    def options_for_using(attribute, options)
      using_options = options.dup
      using_options.delete(:collection)
      using_options[:root] = nil
      using_options[:only] = only_fields(using_options, attribute)
      using_options[:except] = except_fields(using_options, attribute)

      using_options
    end

    # All supported options.
    OPTIONS = [
      :as, :if, :unless, :using, :with, :proc, :documentation, :format_with, :safe, :if_extras, :unless_extras
    ].to_set.freeze

    # Merges the given options with current block options.
    #
    # @param options [Hash] Exposure options.
    def self.merge_options(options)
      opts = {}

      merge_logic = proc do |key, existing_val, new_val|
        if [:if, :unless].include?(key)
          if existing_val.is_a?(Hash) && new_val.is_a?(Hash)
            existing_val.merge(new_val)
          elsif new_val.is_a?(Hash)
            (opts["#{key}_extras".to_sym] ||= []) << existing_val
            new_val
          else
            (opts["#{key}_extras".to_sym] ||= []) << new_val
            existing_val
          end
        else
          new_val
        end
      end

      @block_options ||= []
      opts.merge @block_options.inject({}) { |final, step|
        final.merge(step, &merge_logic)
      }.merge(valid_options(options), &merge_logic)
    end

    # Raises an error if the given options include unknown keys.
    # Renames aliased options.
    #
    # @param options [Hash] Exposure options.
    def self.valid_options(options)
      options.keys.each do |key|
        fail ArgumentError, "#{key.inspect} is not a valid option." unless OPTIONS.include?(key)
      end

      options[:using] = options.delete(:with) if options.key?(:with)
      options
    end
  end
end
