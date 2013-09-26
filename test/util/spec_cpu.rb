require 'pione/test-helper'

describe "Pione::Util::CPU" do
  it "should get number of CPU cores" do
    Util::CPU.core_number.should > 0
  end
end

