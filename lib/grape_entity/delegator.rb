require 'grape_entity/delegator/base'
require 'grape_entity/delegator/hash_object'
require 'grape_entity/delegator/openstruct_object'
require 'grape_entity/delegator/fetchable_object'
require 'grape_entity/delegator/plain_object'

module Grape
  class Entity
    module Delegator
      def self.new(object)
        if object.is_a?(Hash)
          HashObject.new object
        elsif defined?(OpenStruct) && object.is_a?(OpenStruct)
          OpenStructObject.new object
        elsif object.respond_to? :fetch, true
          FetchableObject.new object
        else
          PlainObject.new object
        end
      end
    end
  end
end
