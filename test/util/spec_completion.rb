require 'pione/test-helper'
require 'pione/util/completion'

describe Pione::Util::BashCompletion do
  it "should compile bash completion file" do
    source = Global.project_root + "misc" + "pione-completion.erb"
    target = Location[Temppath.create]
    Util::BashCompletion.compile(source, target)
    target.should.exist
    target.size.should > 0
  end
end

describe Pione::Util::ZshCompletion do
  it "should compile zsh completion file" do
    source = Global.project_root + "misc" + "pione-completion.erb"
    target = Location[Temppath.create]
    Util::ZshCompletion.compile(source, target)
    target.should.exist
    target.size.should > 0
  end
end
