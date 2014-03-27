# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sukremore/version'

Gem::Specification.new do |spec|
  spec.name          = "sukremore"
  spec.version       = Sukremore::VERSION
  spec.authors       = ["Oliver HV"]
  spec.email         = ["oliver.hv@coditramuntana.com"]
  spec.description   = %q{Client for the Rest SugarCRM webservice.}
  spec.summary       = %q{In this very first version only limited access to Account and Contact models is implemented.}
  spec.homepage      = "http://www.coditramuntana.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
