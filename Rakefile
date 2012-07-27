$stand_alone = "bin/pione-stand-alone"

desc 'generate HTML API documentation'
task :html do
  sh "rdoc -x example -x test -x input -x output -x log.txt -f darkfish -o html"
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
    "example/Fib/Fib.pione"
  ]
end

desc 'fib calc with debug mode'
task 'example:Fib:debug' do
  sh "ruby -I lib %s -d %s" % [
    $stand_alone,
    "example/Fib/Fib.pione"
  ]
end

desc 'parser test'
task 'test:parser' do
  sh "bacon -I lib -I test test/parser/spec_*.rb"
end

desc 'transformer test'
task 'test:transformer' do
  sh "bacon -I lib -I test test/transformer/spec_*.rb"
end

desc 'model test'
task 'test:model' do
  sh "bacon -I lib -I test test/model/spec_*.rb"
end

desc 'agent test'
task 'test:agent' do
  sh "bacon -I lib -I test test/agent/spec_*.rb"
end

desc 'rule-handler test'
task 'test:rule-handler' do
  sh "bacon -I lib -I test test/rule-handler/spec_*.rb"
end

desc 'other test'
task 'test:other' do
  sh "bacon -I lib -I test test/spec_*.rb"
end

desc 'clean'
task 'clean' do
  sh "rm -rf input/*"
  sh "rm -rf output/*"
  sh "rm log.txt"
end
