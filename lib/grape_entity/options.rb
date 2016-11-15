module Grape
  class Entity
    class Options
      attr_reader :opts_hash

      def initialize(opts_hash = {})
        @opts_hash = opts_hash
        @has_only = !opts_hash[:only].nil?
        @has_except = !opts_hash[:except].nil?
        @for_nesting_cache = {}
        @should_return_key_cache = {}
      end

      def [](key)
        @opts_hash[key]
      end

      def fetch(*args)
        @opts_hash.fetch(*args)
      end

      def key?(key)
        @opts_hash.key? key
      end

      def merge(new_opts)
        if new_opts.empty?
          self
        else
          merged = if new_opts.instance_of? Options
                     @opts_hash.merge(new_opts.opts_hash)
                   else
                     @opts_hash.merge(new_opts)
                   end
          Options.new(merged)
        end
      end

      def reverse_merge(new_opts)
        if new_opts.empty?
          self
        else
          merged = if new_opts.instance_of? Options
                     new_opts.opts_hash.merge(@opts_hash)
                   else
                     new_opts.merge(@opts_hash)
                   end
          Options.new(merged)
        end
      end

      def empty?
        @opts_hash.empty?
      end

      def ==(other)
        @opts_hash == if other.is_a? Options
                        other.opts_hash
                      else
                        other
                      end
      end

      def should_return_key?(key)
        return true unless @has_only || @has_except

        only = only_fields.nil? ||
               only_fields.key?(key)
        except = except_fields && except_fields.key?(key) &&
                 except_fields[key] == true
        only && !except
      end

      def for_nesting(key)
        @for_nesting_cache[key] ||= build_for_nesting(key)
      end

      def only_fields(for_key = nil)
        return nil unless @has_only

        @only_fields ||= @opts_hash[:only].each_with_object({}) do |attribute, allowed_fields|
          build_symbolized_hash(attribute, allowed_fields)
        end

        only_for_given(for_key, @only_fields)
      end

      def except_fields(for_key = nil)
        return nil unless @has_except

        @except_fields ||= @opts_hash[:except].each_with_object({}) do |attribute, allowed_fields|
          build_symbolized_hash(attribute, allowed_fields)
        end

        only_for_given(for_key, @except_fields)
      end

      def with_attr_path(part)
        stack = (opts_hash[:attr_path] ||= [])
        if part
          stack.push part
          result = yield
          stack.pop
          result
        else
          yield
        end
      end

      private

      def build_for_nesting(key)
        new_opts_hash = opts_hash.dup
        new_opts_hash.delete(:collection)
        new_opts_hash[:root] = nil
        new_opts_hash[:only] = only_fields(key)
        new_opts_hash[:except] = except_fields(key)
        new_opts_hash[:attr_path] = opts_hash[:attr_path]

        Options.new(new_opts_hash)
      end

      def build_symbolized_hash(attribute, hash)
        if attribute.is_a?(Hash)
          attribute.each do |attr, nested_attrs|
            hash[attr.to_sym] = build_symbolized_hash(nested_attrs, {})
          end
        elsif attribute.is_a?(Array)
          return attribute.each { |x| build_symbolized_hash(x, {}) }
        else
          hash[attribute.to_sym] = true
        end

        hash
      end

      def only_for_given(key, fields)
        if key && fields[key].is_a?(Array)
          fields[key]
        elsif key.nil?
          fields
        end
      end
    end
  end
end
