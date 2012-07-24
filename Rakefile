
desc 'generate HTML API documentation'
task :html do
  sh "rdoc -x example -x test -x input -x output -x log.txt -f darkfish -o html"
end

desc 'count characters in input direcotry'
task :CountChar do
  sh "ruby -I lib bin/pione-stand-alone example/CountChar/CountChar.pione"
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
