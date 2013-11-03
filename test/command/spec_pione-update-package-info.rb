require 'pione/test-helper'

describe Pione::Command::PioneUpdatePackageInfo do
  before do
    # package
    @location = Location[Temppath.mkdir]

    # PIONE document
    (@location + "TestPioneUpdatePackageInfo").write(<<-PIONE)
      .@ PackageName :: "TestPioneUpdatePackageInfo"

      Rule Main
        input 'i'
        output 'o'.touch
      End
    PIONE

    # bin
    (@location + "bin" + "test.sh").write("echo 'Hello, world!' > o")

    # scenario
    (@location + "scenario").mkdir

    # scenario document
    (@location + "scenario" + "Scenario.pione").write(<<-PIONE)
      .@ ScenarioName :: "Test"
    PIONE
  end

  it "should update package info files" do
    args = [@location.path.to_s]
    TestHelper::Command.succeed do
      Pione::Command::PioneUpdatePackageInfo.run(args)
    end
    (@location + "pione-package.json").should.exist
    (@location + "pione-package.json").size.should > 0
    (@location + "scenario" + "pione-scenario.json").should.exist
    (@location + "scenario" + "pione-scenario.json").size.should > 0
  end

  it "should not update package info files because they are newer than other files" do
    ptime = (@location + "pione-package.json").write("").mtime
    stime = (@location + "scenario" + "pione-scenario.json").write("").mtime

    args = [@location.path.to_s]
    TestHelper::Command.succeed do
      Pione::Command::PioneUpdatePackageInfo.run(args)
    end

    (@location + "pione-package.json").mtime.should == ptime
    (@location + "scenario" + "pione-scenario.json").mtime.should == stime
  end

  it "should update package info files by 'force' option" do
    ptime = (@location + "pione-package.json").write("").mtime
    stime = (@location + "scenario" + "pione-scenario.json").write("").mtime

    args = [@location.path.to_s, "--force"]
    TestHelper::Command.succeed do
      Pione::Command::PioneUpdatePackageInfo.run(args)
    end

    (@location + "pione-package.json").mtime.should > ptime
    (@location + "scenario" + "pione-scenario.json").mtime.should > stime
  end
end
