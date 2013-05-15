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
  gem.description   = %q{PIONE(Process-rule for Input/Output Negotiation Enviromenment) is a rule-based workflow engine.}
  gem.summary       = %q{rule-based workflow engine}
  gem.homepage      = "http://pione.github.com/"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 1.9.2'

  #
  # dependencies
  #

  # requisite for system
  gem.add_dependency "parslet", "~> 1.5.0"
  gem.add_dependency "uuidtools", "~> 2.1.3"
  gem.add_dependency "highline", "~> 1.6.15"
  gem.add_dependency "hamster", "~> 0.4"
  gem.add_dependency "naming"
  gem.add_dependency "forwardablex", "~> 0.1.3"
  gem.add_dependency "temppath"
  gem.add_dependency "ruby-xes", "~> 0.1"
  gem.add_dependency "sys-uname"

  # for locations
  gem.add_dependency "dropbox-sdk"
  gem.add_dependency "em-ftpd"

  # for web client only
  gem.add_dependency "sinatra"
  gem.add_dependency "thin"

  # test framework
  gem.add_development_dependency "bacon", "~> 1.2.0"

  # maintainanse tools
  gem.add_development_dependency "rake"
  gem.add_development_dependency "bundler"

  # for documentation
  gem.add_development_dependency "yard"
  gem.add_development_dependency "redcarpet"
end
