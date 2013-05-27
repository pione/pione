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

  gem.required_ruby_version = '>= 1.9.3'

  #
  # dependencies
  #

  # requisite for system
  gem.add_dependency "parslet", "~> 1.5.0"
  gem.add_dependency "uuidtools", "~> 2.1.4"
  gem.add_dependency "highline", "~> 1.6.15"
  gem.add_dependency "hamster", "~> 0.4.3"
  gem.add_dependency "naming", "~> 0.0.2"
  gem.add_dependency "forwardablex", "~> 0.1.4"
  gem.add_dependency "temppath", "~> 0.1.1"
  gem.add_dependency "ruby-xes", "~> 0.1.0"
  gem.add_dependency "sys-uname", "~> 0.9.2"
  gem.add_dependency "simple-identity", "~> 0.1.1"
  gem.add_dependency "rainbow", "~> 1.1.4"
  gem.add_dependency "sys-cpu", "~> 0.7.1"
  gem.add_dependency "structx", "~> 0.1.0"
  gem.add_dependency "syslog-logger", "~> 1.6.8"

  # for locations
  gem.add_dependency "dropbox-sdk", "~> 1.5.1"
  gem.add_dependency "em-ftpd", "~> 0.0.1"

  # test framework
  gem.add_development_dependency "bacon", "~> 1.2.0"

  # maintainanse tools
  gem.add_development_dependency "rake"
  gem.add_development_dependency "bundler"

  # for documentation
  gem.add_development_dependency "yard"
  gem.add_development_dependency "redcarpet"  unless RUBY_PLATFORM == 'java'
end
