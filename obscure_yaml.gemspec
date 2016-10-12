# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)
require 'obscure_yaml/version'

Gem::Specification.new do |s|
  s.name        = 'obscure_yaml'
  s.version     = ObscureYaml::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Brian Glusman']
  s.email       = ['brian@stellaservice.com']
  s.homepage    = 'https://github.com/stellaservice/obscure_yaml'
  s.license     = 'MIT'
  s.summary     = 'Obscure YAML produces and consumes obscure yaml via base64 encoding/decoding and referenced files'
  s.rubyforge_project = 'obscure_yaml'
  s.require_paths = ['lib']
  s.add_development_dependency 'rspec', '~> 3.5'
  s.add_runtime_dependency 'deep_merge', '~> 1.1'

  s.description = <<-DESC
    There was no call for this really, except we needed it.
  DESC

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
