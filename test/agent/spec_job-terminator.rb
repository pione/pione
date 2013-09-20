require_relative '../test-util'

describe 'Pione::Agent::JobTerminator' do
  before do
    @tuple_space = create_tuple_space_server
  end

  after do
    @tuple_space.terminate
  end

  it 'should fire the termination action' do
    fired = false

    # create an agent
    job_terminator = Agent::JobTerminator.start(@tuple_space) {fired = true}

    # write terminate command
    write(Tuple[:command].new(name: "terminate", args: []))

    # wait termination
    job_terminator.wait_until_terminated

    # test
    fired.should.be.true
  end
end
