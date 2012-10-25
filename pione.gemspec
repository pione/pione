# -*- ruby -*-
# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pione/version'

Gem::Specification.new do |gem|
  gem.name          = "pione"
  gem.version       = Pione::VERSION
  gem.authors       = ["Keita Yamaguchi"]
  gem.email         = ["keita.yamaguchi@gmail.com"]
  gem.description   = %q{PIONE is Process-rule for Input/Output Negotiation Enviromenment.}
  gem.summary       = %q{PIONE is Process-rule for Input/Output Negotiation Enviromenment.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency "bacon", "~> 1.1.0"
  gem.add_runtime_dependency "parslet", "~> 1.4.0"
  gem.add_runtime_dependency "json", "~> 1.7.5"
  gem.add_runtime_dependency "uuidtools", "~> 2.1.3"
  gem.add_runtime_dependency "highline", "~> 1.6.15"
end
