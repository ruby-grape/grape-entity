# frozen_string_literal: true

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
      def root_exposure
        @root_exposure ||= Exposure.new(nil, nesting: true)
      end

      attr_writer :root_exposure

      # Returns all formatters that are registered for this and it's ancestors
      # @return [Hash] of formatters
      def formatters
        @formatters ||= {}
      end

      attr_writer :formatters
    end

    @formatters = {}

    def self.inherited(subclass)
      subclass.root_exposure = root_exposure.dup
      subclass.formatters = formatters.dup
    end

    # This method is the primary means by which you will declare what attributes
    # should be exposed by the entity.
    #
    # @option options :expose_nil When set to false the associated exposure will not
    #   be rendered if its value is nil.
    #
    # @option options :as Declare an alias for the representation of this attribute.
    #   If a proc is presented it is evaluated in the context of the entity so object
    #   and the entity methods are available to it.
    #
    # @example as: a proc or lambda
    #
    #   object = OpenStruct(awesomness: 'awesome_key', awesome: 'not-my-key', other: 'other-key' )
    #
    #   class MyEntity < Grape::Entity
    #     expose :awesome, as: proc { object.awesomeness }
    #     expose :awesomeness, as: ->(object, opts) { object.other }
    #   end
    #
    #   => { 'awesome_key': 'not-my-key', 'other-key': 'awesome_key' }
    #
    # Note the parameters passed in via the lambda syntax.
    #
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
    # @option options :merge This option allows you to merge an exposed field to the root
    def self.expose(*args, &block)
      options = merge_options(args.last.is_a?(Hash) ? args.pop : {})

      if args.size > 1
        raise ArgumentError, 'You may not use the :as option on multi-attribute exposures.' if options[:as]
        raise ArgumentError, 'You may not use the :expose_nil on multi-attribute exposures.' if options.key?(:expose_nil)
        raise ArgumentError, 'You may not use block-setting on multi-attribute exposures.' if block_given?
      end

      raise ArgumentError, 'You may not use block-setting when also using format_with' if block_given? && options[:format_with].respond_to?(:call)

      if block_given?
        if block.parameters.any?
          options[:proc] = block
        else
          options[:nesting] = true
        end
      end

      @documentation = nil
      @nesting_stack ||= []
      args.each { |attribute| build_exposure_for_attribute(attribute, @nesting_stack, options, block) }
    end

    def self.build_exposure_for_attribute(attribute, nesting_stack, options, block)
      exposure_list = nesting_stack.empty? ? root_exposures : nesting_stack.last.nested_exposures

      exposure = Exposure.new(attribute, options)

      exposure_list.delete_by(attribute) if exposure.override?

      exposure_list << exposure

      # Nested exposures are given in a block with no parameters.
      return unless exposure.nesting?

      nesting_stack << exposure
      block.call
      nesting_stack.pop
    end

    # Returns exposures that have been declared for this Entity on the top level.
    # @return [Array] of exposures
    def self.root_exposures
      root_exposure.nested_exposures
    end

    def self.find_exposure(attribute)
      root_exposures.find_by(attribute)
    end

    def self.unexpose(*attributes)
      cannot_unexpose! unless can_unexpose?
      @documentation = nil
      root_exposures.delete_by(*attributes)
    end

    def self.unexpose_all
      cannot_unexpose! unless can_unexpose?
      @documentation = nil
      root_exposures.clear
    end

    def self.can_unexpose?
      (@nesting_stack ||= []).empty?
    end

    def self.cannot_unexpose!
      raise "You cannot call 'unexpose` inside of nesting exposure!"
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
      @documentation ||= root_exposures.each_with_object({}) do |exposure, memo|
        memo[exposure.key] = exposure.documentation if exposure.documentation && !exposure.documentation.empty?
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
      raise ArgumentError, 'You must pass a block for formatters' unless block_given?
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
    #         expose :items, as: 'users', using: API::Entities::User
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
      @present_collection ||= nil
      if objects.respond_to?(:to_ary) && !@present_collection
        root_element = root_element(:collection_root)
        inner = objects.to_ary.map { |object| new(object, options.reverse_merge(collection: true)).presented }
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
      instance_variable = "@#{root_type}"
      if instance_variable_defined?(instance_variable) && instance_variable_get(instance_variable)
        instance_variable_get(instance_variable)
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

    # Prevent default serialization of :options or :delegator.
    def inspect
      fields = serializable_hash.map { |k, v| "#{k}=#{v}" }
      "#<#{self.class.name}:#{object_id} #{fields.join(' ')}>"
    end

    def initialize(object, options = {})
      @object = object
      @delegator = Delegator.new(object)
      @options = options.is_a?(Options) ? options : Options.new(options)
    end

    def root_exposures
      self.class.root_exposures
    end

    def root_exposure
      self.class.root_exposure
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

      root_exposure.serializable_value(self, opts)
    end

    def exec_with_object(options, &block)
      if block.parameters.count == 1
        instance_exec(object, &block)
      else
        instance_exec(object, options, &block)
      end
    end

    def exec_with_attribute(attribute, &block)
      instance_exec(delegate_attribute(attribute), &block)
    end

    def value_for(key, options = Options.new)
      root_exposure.valid_value_for(key, self, options)
    end

    def delegate_attribute(attribute)
      if respond_to?(attribute, true) && Grape::Entity > method(attribute).owner
        send(attribute)
      else
        delegator.delegate(attribute)
      end
    end

    alias as_json serializable_hash

    def to_json(options = {})
      options = options.to_h if options && options.respond_to?(:to_h)
      MultiJson.dump(serializable_hash(options))
    end

    def to_xml(options = {})
      options = options.to_h if options && options.respond_to?(:to_h)
      serializable_hash(options).to_xml(options)
    end

    # All supported options.
    OPTIONS = %i[
      rewrite as if unless using with proc documentation format_with safe attr_path if_extras unless_extras merge expose_nil override
    ].to_set.freeze

    # Merges the given options with current block options.
    #
    # @param options [Hash] Exposure options.
    def self.merge_options(options)
      opts = {}

      merge_logic = proc do |key, existing_val, new_val|
        if %i[if unless].include?(key)
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
      options.each_key do |key|
        raise ArgumentError, "#{key.inspect} is not a valid option." unless OPTIONS.include?(key)
      end

      options[:using] = options.delete(:with) if options.key?(:with)
      options
    end
  end
end
