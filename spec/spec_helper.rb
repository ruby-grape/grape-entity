$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support'))

require 'rubygems'
require 'bundler'

Bundler.require :default, :test

require 'pry'

RSpec.configure do |config|
  config.raise_errors_for_deprecations!
end

module Grape
  class Entity
    # Returns an array of symbolized unique attributes mapped to the provided common attribute.
    # @param [Symbol] common_attribute
    def self.unique_attributes_for(common_attribute)
      attribute_maps.select { |_, v| v == common_attribute.to_sym }.map { |k, _| k }
    end
    def unique_attributes_for(common_attribute)
      self.class.unique_attributes_for(common_attribute)
    end

    # Returns the first symbolized unique attribute mapped to the provided common attribute.
    # @param [Symbol] common_attribute
    def self.unique_attribute_for(common_attribute)
      unique_attributes_for(common_attribute).first
    end
    def unique_attribute_for(common_attribute)
      self.class.unique_attribute_for(common_attribute)
    end
  end
end
