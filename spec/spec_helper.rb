# frozen_string_literal: true

require 'simplecov'
require 'coveralls'

SimpleCov.start do
  add_filter 'spec/'
end

Coveralls.wear!

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support'))

require 'rubygems'
require 'bundler'

Bundler.require :default, :test

RSpec.configure(&:raise_errors_for_deprecations!)
