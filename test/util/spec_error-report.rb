require_relative "../test-util"

describe "Pione::Util::ErrorReport" do
  before do
    $stderr = StringIO.new("", "w")
    @rec = Object.new
    @exc = Exception.new.tap{|x| x.set_backtrace(caller)}
    @file = __FILE__
    @line = __LINE__
  end

  after do
    $stderr = STDERR
  end

  it "should print" do
    Util::ErrorReport.print(@exc)
    $stderr.string.should.include @exe.to_s
  end

  it "should warn in debug mode" do
    Pione.debug_mode {Util::ErrorReport.warn("test warning", @rec, @exc, @file, @line)}
    $stderr.string.tap do |s|
      s.should.include "test warning"
      s.should.include @rec.to_s
      s.should.include @exc.to_s
      s.should.include @file.to_s
      s.should.include @line.to_s
    end
  end

  it "should not warn in normal mode" do
    Util::ErrorReport.warn("test warning", @rec, @exc, @file, @line)
    $stderr.string.tap do |s|
      s.should.not.include "test warning"
      s.should.not.include @rec.to_s
      s.should.not.include @exc.to_s
      s.should.not.include @file.to_s
      s.should.not.include @line.to_s
    end
  end
end
