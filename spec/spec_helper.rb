$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support'))

# $stdout = StringIO.new

require 'rubygems'
require 'bundler'
Bundler.require :default, :test

require 'pry'
require 'base64'
