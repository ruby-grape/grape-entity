# frozen_string_literal: true

source 'http://rubygems.org'

gemspec

group :development, :test do
  gem 'bundler'
  # activesupport 7.1 (the newest on Ruby 3.0) passes `quirks_mode:` to JSON.generate, which json 3.0 removed
  gem 'json', '< 3.0' if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.1')
  gem 'maruku'
  gem 'ostruct' # no longer a default gem in Ruby 4.0
  gem 'pry' unless RUBY_PLATFORM.eql?('java') || RUBY_ENGINE.eql?('rbx')
  gem 'pry-byebug' unless RUBY_PLATFORM.eql?('java') || RUBY_ENGINE.eql?('rbx')
  gem 'rack-test'
  gem 'rake'
  gem 'rspec', '~> 3.9'
  gem 'rubocop', '~> 1.90' # the disable-next directive needs 1.90
  gem 'yard'
end

group :test do
  gem 'coveralls_reborn', require: false
  gem 'danger', require: false
  gem 'danger-changelog', require: false
  gem 'danger-pr-comment', require: false
  gem 'git', '< 6' # danger 9.6 references Git::Base, which git 6 no longer loads eagerly; drop once danger supports git 6
  gem 'growl'
  gem 'guard'
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'rb-fsevent'
  gem 'simplecov', require: false
end
