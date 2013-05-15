require "bundler/gem_tasks"

$stand_alone = "bin/pione-client --stand-aline"

desc 'generate HTML API documentation'
task 'html' do
  sh 'bundle exec yard doc -o html --hide-void-return --no-api --private'
end

desc 'Show undocumented function list'
task 'html:undoc' do
  sh 'bundle exec yard stats --list-undoc --no-api --private --compact'
end

desc 'count characters in input direcotry'
task 'example:CountChar' do
  sh "ruby -I lib %s -i %s %s" % [
    $stand_alone,
    "example/CountChar/text",
    "example/CountChar/CountChar.pione"
  ]
end

desc 'count characters in input direcotry with debug mode'
task 'example:CountChar:debug_mode' do
  sh "ruby -I lib %s -i %s -d %s" % [
    $stand_alone,
    "example/CountChar/text",
    "example/CountChar/CountChar.pione"
  ]
end

desc 'count characters by stream'
task 'example:CountCharStream' do
  sh "ruby -I lib %s -s %s" % [
    $stand_alone,
    "example/CountChar/CountCharStream.pione"
  ]
end

desc 'count characters by stream with debug mode'
task 'example:CountCharStream:debug_mode' do
  sh "ruby -I lib %s -s -d %s" % [
    $stand_alone,
    "example/CountChar/CountCharStream.pione"
  ]
end

desc 'sum numbers in file'
task 'example:Sum' do
  sh "ruby -I lib %s -i %s %s" % [
    $stand_alone,
    "example/Sum/input",
    "example/Sum/Sum.pione"
  ]
end

desc 'sum numbers in file with debug mode'
task 'example:Sum:debug_mode' do
  sh "ruby -I lib %s -i %s -d %s" % [
    $stand_alone,
    "example/Sum/input",
    "example/Sum/Sum.pione"
  ]
end

desc 'fib calc'
task 'example:Fib' do
  sh "ruby -I lib %s %s" % [
    $stand_alone,
    "example/Fib/Fib.pione",
  ]
end

desc 'fib calc with debug mode'
task 'example:Fib:debug' do
  sh "ruby -I lib %s -d %s" % [
    $stand_alone,
    "example/Fib/Fib.pione"
  ]
end

desc 'execute basic tests'
task 'test' do
  sh "bundle exec bacon -I lib test/parser/spec_*.rb test/transformer/spec_*.rb test/model/spec_*.rb test/log/spec_*.rb"
end

desc 'parser test'
task 'test:parser' do
  sh "bundle exec bacon -I lib test/parser/spec_*.rb"
end

desc 'transformer test'
task 'test:transformer' do
  sh "bundle exec bacon -I lib test/transformer/spec_*.rb"
end

desc 'model test'
task 'test:model' do
  sh "bundle exec bacon -I lib test/model/spec_*.rb"
end

desc 'agent test'
task 'test:agent' do
  sh "bundle exec bacon -I lib test/agent/spec_*.rb"
end

desc 'rule-handler test'
task 'test:rule-handler' do
  sh "bundle exec bacon -I lib test/rule-handler/spec_*.rb"
end

desc 'log test'
task 'test:log' do
  sh "bundle exec bacon -I lib test/log/spec_*.rb"
end

desc 'other test'
task 'test:other' do
  sh "bundle exec bacon -I lib test/spec_*.rb"
end

desc 'clean'
task 'clean' do
  sh "rm -rf input/*"
  sh "rm -rf output/*"
  sh "rm -rf log.txt"
end
