# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'grape_entity/version'

Gem::Specification.new do |s|
  s.name        = 'grape-entity'
  s.version     = GrapeEntity::VERSION
  s.authors     = ['LeFnord', 'Michael Bleigh']
  s.email       = ['pscholz.le@gmail.com', 'michael@intridea.com']
  s.homepage    = 'https://github.com/ruby-grape/grape-entity'
  s.summary     = 'A simple facade for managing the relationship between your model and API.'
  s.description = 'Extracted from Grape, A Ruby framework for rapid API development with great conventions.'
  s.license     = 'MIT'

  s.metadata = {
    'homepage_uri' => 'https://github.com/ruby-grape/grape-entity',
    'bug_tracker_uri' => 'https://github.com/ruby-grape/grape-entity/issues',
    'changelog_uri' => "https://github.com/ruby-grape/grape-entity/blob/v#{s.version}/CHANGELOG.md",
    'documentation_uri' => "https://www.rubydoc.info/gems/grape-entity/#{s.version}",
    'source_code_uri' => "https://github.com/ruby-grape/grape-entity/tree/v#{s.version}",
    'rubygems_mfa_required' => 'true'
  }

  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'activesupport', '>= 3.0.0'

  s.files         = Dir['lib/**/*.rb', 'CHANGELOG.md', 'LICENSE', 'README.md']
  s.require_paths = ['lib']
end
