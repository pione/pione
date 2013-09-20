require "bundler/gem_tasks"
require "pione"

desc 'generate HTML API documentation'
task 'html' do
  sh 'bundle exec yard doc -o html --hide-void-return --no-api --private'
end

desc 'Show undocumented function list'
task 'html:undoc' do
  sh 'bundle exec yard stats --list-undoc --no-api --private --compact'
end

desc 'execute basic tests'
task 'test' do
  sh "bundle exec bacon -I lib -rsimplecov test/parser/spec_*.rb test/transformer/spec_*.rb test/log/spec_*.rb test/location/spec_*.rb test/component/spec_*.rb test/util/spec_*.rb test/tuple/spec_*.rb test/uri-scheme/spec_*.rb test/agent/spec_*.rb test/rule-engine/spec_*.rb test/system/spec_*.rb test/command/spec_*.rb"
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

desc "create test git package"
task "test:build-test-git-package" do
  path = Temppath.mkdir
  cd path do
    sh "git clone https://github.com/pione/HelloWorld.git"
    # sh "zip HelloWorld.zip -r HelloWorld"
    Util::Zip.compress(Location["HelloWorld"], Location["HelloWorld.zip"])
  end
  sh "mkdir -p test/test-data/git-repository/"
  sh "mv %s %s" % [File.join(path, "HelloWorld.zip"), "test/test-data/git-repository/"]
end

desc 'clean'
task 'clean' do
  sh "rm -rf input/*"
  sh "rm -rf output/*"
  sh "rm -rf log.txt"
end
