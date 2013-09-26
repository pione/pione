require 'coveralls'
Coveralls.wear!
SimpleCov.command_name 'bacon'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start {add_filter 'test'}
