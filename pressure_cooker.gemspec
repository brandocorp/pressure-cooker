# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pressure_cooker/version'

Gem::Specification.new do |spec|
  spec.name          = "pressure_cooker"
  spec.version       = PressureCooker::VERSION
  spec.authors       = ["Brandon Raabe"]
  spec.email         = ["Brandon.Raabe@apollogrp.edu"]
  spec.description   = %q{Put on your Chef hat and get cookin'}
  spec.summary       = %q{CLI-driven automated workflow for Chef development}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "git", "~> 1.2.6"
  spec.add_runtime_dependency "jiralicious", "~> 0.4.0"
  spec.add_runtime_dependency "jenkins_api_client", "~> 0.14.1"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
