require 'pione/test-helper'

describe "example/MakePair" do
  TestHelper::PioneClientRunner.test(self) do |runner|
    runner.title = "should get a result of example/MakePair"
    runner.args = ["example/MakePair", "--rehearse", "case1", *runner.default_arguments]
    runner.run do |base|
      1.upto(5) do |i|
        1.upto(5) do |ii|
          comb = (base + "output" + "comb-%s-%s.pair" % [i, ii])
          i < ii ? comb.should.exist : comb.should.not.exist
          perm = (base + "output" + "perm-%s-%s.pair" % [i, ii])
          i != ii ? perm.should.exist : perm.should.not.exist
          succ = (base + "output" + "succ-%s-%s.pair" % [i, ii])
          ii - i == 1 ? succ.should.exist : succ.should.not.exist
        end
      end
    end
  end
end
