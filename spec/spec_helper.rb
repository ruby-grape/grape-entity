# frozen_string_literal: true

require 'simplecov'
require 'coveralls'

# This works around the hash extensions not being automatically included in ActiveSupport < 4
require 'active_support/version'
require 'active_support/core_ext/hash' if ActiveSupport::VERSION &&
                                          ActiveSupport::VERSION::MAJOR &&
                                          ActiveSupport::VERSION::MAJOR < 4

SimpleCov.start do
  add_filter 'spec/'
end

Coveralls.wear! unless RUBY_PLATFORM.eql? 'java'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support'))

require 'rubygems'
require 'bundler'

Bundler.require :default, :test

RSpec.configure(&:raise_errors_for_deprecations!)
