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
  spec.homepage      = "http://wiki.apollogrp.edu/Chef"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "git", "~> 1.2.6"
  spec.add_runtime_dependency "jiralicious", "~> 0.4.0"
  spec.add_runtime_dependency "bamboo-client", "~> 0.1.7"
  spec.add_runtime_dependency "chef", "10.12.0"
  spec.add_runtime_dependency "moneta", "0.6.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "foodcritic", "3.0.3"
  spec.add_development_dependency "berkshelf"
  spec.add_development_dependency "test-kitchen", ">= 1.0.0.beta.3"
  spec.add_development_dependency "kitchen-vagrant", "0.11.3"
  spec.add_development_dependency "kitchen-ec2"
  spec.add_development_dependency "minitest-chef-handler"
end
