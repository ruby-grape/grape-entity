source 'http://rubygems.org'

gemspec

current_ruby_version = Gem::Version.new(RUBY_VERSION)

if Gem::Requirement.new('>= 2.2.2').satisfied_by? current_ruby_version
  gem 'activesupport', '~> 5.0'
  gem 'rack', '~> 2.0', group: [:development, :test]
else
  gem 'activesupport', '~> 4.0'
  gem 'rack', '< 2', group: [:development, :test]
end

gem 'json', '< 2', group: [:development, :test]

group :development do
  gem 'pry'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'rb-fsevent'
  gem 'growl'
end

group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'rack-test', '~> 0.6.2', require: 'rack/test'
  gem 'rubocop', '0.31.0'
end

group :test do
  gem 'ruby-grape-danger', '~> 0.1.0', require: false
end
