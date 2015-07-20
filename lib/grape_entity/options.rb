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
        if other.is_a? Options
          @opts_hash == other.opts_hash
        else
          @opts_hash == other
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
          if attribute.is_a?(Hash)
            attribute.each do |attr, nested_attrs|
              allowed_fields[attr] ||= []
              allowed_fields[attr] += nested_attrs
            end
          else
            allowed_fields[attribute] = true
          end
        end.symbolize_keys

        if for_key && @only_fields[for_key].is_a?(Array)
          @only_fields[for_key]
        elsif for_key.nil?
          @only_fields
        end
      end

      def except_fields(for_key = nil)
        return nil unless @has_except

        @except_fields ||= @opts_hash[:except].each_with_object({}) do |attribute, allowed_fields|
          if attribute.is_a?(Hash)
            attribute.each do |attr, nested_attrs|
              allowed_fields[attr] ||= []
              allowed_fields[attr] += nested_attrs
            end
          else
            allowed_fields[attribute] = true
          end
        end.symbolize_keys

        if for_key && @except_fields[for_key].is_a?(Array)
          @except_fields[for_key]
        elsif for_key.nil?
          @except_fields
        end
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
    end
  end
end
