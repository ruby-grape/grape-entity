$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'grape_entity/version'

Gem::Specification.new do |s|
  s.name        = 'grape-entity'
  s.version     = GrapeEntity::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Michael Bleigh']
  s.email       = ['michael@intridea.com']
  s.homepage    = 'https://github.com/ruby-grape/grape-entity'
  s.summary     = 'A simple facade for managing the relationship between your model and API.'
  s.description = 'Extracted from Grape, A Ruby framework for rapid API development with great conventions.'
  s.license     = 'MIT'

  s.rubyforge_project = 'grape-entity'

  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'multi_json', '>= 1.3.2'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'maruku'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'rspec', '~> 2.9'
  s.add_development_dependency 'bundler'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
