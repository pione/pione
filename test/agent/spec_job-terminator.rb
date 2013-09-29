require 'pione/test-helper'

describe 'Pione::Agent::JobTerminator' do
  before do
    @tuple_space = TestHelper::TupleSpace.create(self)
  end

  after do
    @tuple_space.terminate
  end

  it 'should fire the termination action' do
    fired = false

    # create an agent
    job_terminator = Agent::JobTerminator.start(@tuple_space) {fired = true}

    # write terminate command
    write(TupleSpace::CommandTuple.new(name: "terminate", args: []))

    # wait termination
    job_terminator.wait_until_terminated

    # test
    fired.should.be.true
  end
end
