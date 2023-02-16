# frozen_string_literal: true

source 'http://rubygems.org'

gemspec

group :development, :test do
  gem 'bundler'
  gem 'maruku'
  gem 'pry' unless RUBY_PLATFORM.eql?('java') || RUBY_ENGINE.eql?('rbx')
  gem 'pry-byebug' unless RUBY_PLATFORM.eql?('java') || RUBY_ENGINE.eql?('rbx')
  gem 'rack-test'
  gem 'rake'
  gem 'rspec', '~> 3.9'
  gem 'rubocop', '~> 1.0'
  gem 'yard'
end

group :test do
  gem 'coveralls_reborn', require: false
  gem 'growl'
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'rb-fsevent'
  gem 'ruby-grape-danger', '~> 0.2', require: false
  gem 'simplecov', require: false
end
