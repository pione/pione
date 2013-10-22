# -*- ruby -*-
# -*- encoding: utf-8 -*-

# load PIONE's version
require File.expand_path('pione/version', File.join(File.dirname(__FILE__), "lib"))

Gem::Specification.new do |gem|
  #
  # basic information
  #

  gem.name        = "pione"
  gem.version     = Pione::VERSION
  gem.authors     = ["Keita Yamaguchi"]
  gem.email       = ["keita.yamaguchi@gmail.com"]
  gem.description = %q{PIONE(Process-rule for Input/Output Negotiation Enviromenment) is a rule-based workflow engine.}
  gem.summary     = %q{rule-based workflow engine}
  gem.homepage    = "http://pione.github.com/"
  gem.license     = "MIT"

  #
  # files
  #

  gem.files       = `git ls-files`.split($/)
  gem.executables = gem.files.grep(%r{^bin/}).map{|f| File.basename(f)}
  gem.test_files  = gem.files.grep(%r{^(test/|lib/pione/test-helper)})

  #
  # dependencies
  #

  # ruby version
  gem.required_ruby_version = '>= 1.9.3'

  # requisite for system
  gem.add_runtime_dependency "parslet", "~> 1.5.0"
  gem.add_runtime_dependency "uuidtools", "~> 2.1.4"
  gem.add_runtime_dependency "highline", "~> 1.6.20"
  gem.add_runtime_dependency "hamster", "~> 0.4.3"
  gem.add_runtime_dependency "naming", "~> 0.1.0"
  gem.add_runtime_dependency "forwardablex", "~> 0.1.4"
  gem.add_runtime_dependency "temppath", "~> 0.2.0"
  gem.add_runtime_dependency "ruby-xes", "~> 0.1.0"
  gem.add_runtime_dependency "sys-uname", "~> 0.9.2"
  gem.add_runtime_dependency "simple-identity", "~> 0.1.1"
  gem.add_runtime_dependency "rainbow", "~> 1.1.4"
  gem.add_runtime_dependency "sys-cpu", "~> 0.7.1"
  gem.add_runtime_dependency "structx", "~> 0.1.3"
  gem.add_runtime_dependency "syslog-logger", "~> 1.6.8"
  gem.add_runtime_dependency "retriable", "~> 1.3.3"
  gem.add_runtime_dependency "childprocess", "~> 0.3.9"
  gem.add_runtime_dependency "lettercase", "~> 0.0.3"
  gem.add_runtime_dependency "rubyzip", "~> 1.0.0"

  # for locations
  gem.add_runtime_dependency "dropbox-sdk", "~> 1.5.1"
  gem.add_runtime_dependency "em-ftpd", "~> 0.0.1"

  # test framework
  gem.add_development_dependency "bacon", "~> 1.2.0"

  # maintainanse tools
  gem.add_development_dependency "rake"
  gem.add_development_dependency "bundler"

  # for documentation
  gem.add_development_dependency "yard"
  gem.add_development_dependency "redcarpet" unless RUBY_PLATFORM == 'java'

  # profiler
  gem.add_development_dependency "ruby-prof" unless RUBY_PLATFORM == 'java'
end
