# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)
require 'ky/version'

Gem::Specification.new do |s|
  s.name        = 'ky'
  s.version     = KY::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Brian Glusman']
  s.email       = ['brian@stellaservice.com']
  s.homepage    = 'https://github.com/stellaservice/ky'
  s.license     = 'MIT'
  s.summary     = 'Kubernetes Yaml utilities and lubricant'
  s.rubyforge_project = 'ky'
  s.require_paths = ['lib']
  s.add_development_dependency 'rake', '~> 11.3'
  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_development_dependency 'pry', '~> 0.10'
  s.add_runtime_dependency 'thor', '~> 0.19'
  s.add_runtime_dependency 'activesupport', '>= 3.0'
  s.add_runtime_dependency 'deep_merge', '~> 1.1'
  s.add_runtime_dependency 'deterministic_random_username', '~> 1.0'

  s.description = <<-DESC
    Utility belt for generating kubernetes deployment, config and secrets yml files
  DESC

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
