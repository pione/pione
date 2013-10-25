require 'pione/test-helper'

describe Pione::Agent::JobTerminator do
  before do
    @tuple_space = TestHelper::TupleSpace.create(self)
  end

  after do
    @tuple_space.terminate
  end

  it 'should fire the termination action with success status' do
    fired = false
    result = nil

    # create an agent
    job_terminator = Agent::JobTerminator.start(@tuple_space) do |status|
      fired = true
      result = status.success?
    end

    # write terminate command
    write(TupleSpace::CommandTuple.new(name: "terminate", args: []))

    # wait termination
    job_terminator.wait_until_terminated

    # test
    fired.should.be.true
    result.should.be.true
  end

  it 'should fire the termination action with failure status' do
    fired = false
    result = nil

    # create an agent
    job_terminator = Agent::JobTerminator.start(@tuple_space) do |status|
      fired = true
      result = status.success?
    end

    # write terminate command
    write(TupleSpace::CommandTuple.new(name: "terminate", args: [System::Status.error(Exception.new)]))

    # wait termination
    job_terminator.wait_until_terminated

    # test
    fired.should.be.true
    result.should.be.false
  end

  it "should terminate" do
    # create an agent
    job_terminator = Agent::JobTerminator.start(@tuple_space) do |status|
      fired = true
      result = status.success?
    end

    # termination
    job_terminator.terminate
    job_terminator.should.terminated
  end
end
