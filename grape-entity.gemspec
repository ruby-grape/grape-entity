# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'grape_entity/version'

Gem::Specification.new do |s|
  s.name        = 'grape-entity'
  s.version     = GrapeEntity::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['LeFnord', 'Michael Bleigh']
  s.email       = ['pscholz.le@gmail.com', 'michael@intridea.com']
  s.homepage    = 'https://github.com/ruby-grape/grape-entity'
  s.summary     = 'A simple facade for managing the relationship between your model and API.'
  s.description = 'Extracted from Grape, A Ruby framework for rapid API development with great conventions.'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.0'

  s.add_runtime_dependency 'activesupport', '>= 3.0.0'
  # FIXME: remove dependecy
  s.add_runtime_dependency 'multi_json', '>= 1.3.2'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec}/*`.split("\n")
  s.require_paths = ['lib']
end
