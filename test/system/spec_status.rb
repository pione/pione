require 'pione/test-helper'

describe Pione::System::Status do
  it "should get success" do
    System::Status.success.should.success
    System::Status.success.should.not.error
  end

  it "should get error" do
    System::Status.error(Exception.new).should.error
    System::Status.error(Exception.new).should.not.success
  end
end
