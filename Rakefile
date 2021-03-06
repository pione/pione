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
  sh "bundle exec bacon -rsimplecov -a"
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

#
# man
#

def generate_man(src, dest)
  sh "pandoc -s --from=markdown+pandoc_title_block --to=man %s > %s" % [src, dest]
end

desc "generate man documents"
task "man" do
  generate_man("doc/man/pione-clean.md", "man/pione-clean.1")
  generate_man("doc/man/pione-compiler.md", "man/pione-compiler.1")
  generate_man("doc/man/pione-update-package-info.md", "man/pione-update-package-info.1")
  generate_man("doc/man/pione-action.md", "man/pione-action.1")
  generate_man("doc/man/pione-action-list.md", "man/pione-action-list.1")
  generate_man("doc/man/pione-list-param.md", "man/pione-list-param.1")
end

#
# Completion
#

desc "generate bash completion file"
task "completion:bash" do
  Pione::Command.load_all
  require 'pione/util/completion'
  misc = Pione::Location[File.dirname(__FILE__)] + "misc"
  source = misc + "pione-completion.erb"
  target = misc + "pione-completion.bash"
  Pione::Util::BashCompletion.compile(source, target)
end

desc "generate zsh completion file"
task "completion:zsh" do
  Pione::Command.load_all
  require 'pione/util/completion'
  misc = Pione::Location[File.dirname(__FILE__)] + "misc"
  source = misc + "pione-completion.erb"
  target = misc + "pione-completion.zsh"
  Pione::Util::ZshCompletion.compile(source, target)
end
