source 'http://rubygems.org'

gemspec

if RUBY_VERSION < '2.2.2'
  gem 'rack', '<2.0.0'
  gem 'activesupport', '<5.0.0'
end

gem 'json', '< 2', group: [:development, :test]

group :development, :test do
  gem 'rubocop', '0.31.0'
  gem 'ruby-grape-danger', '~> 0.1.0', require: false
end

group :test do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'rb-fsevent'
  gem 'growl'
end
