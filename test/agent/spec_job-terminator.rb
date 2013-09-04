require_relative '../test-util'

class TestAgent < Pione::Agent::BasicAgent
  def initialize(space)
    super()
    @job_terminator = Pione::Agent::JobTerminator.start(space, self)
  end

  define_transition :test

  chain :init => :test
  chain :test => :test

  def transit_to_test
    sleep 0.1
  end
end

describe 'Pione::Agent::JobTerminator' do
  before do
    @space = create_tuple_space_server
  end

  after do
    @space.terminate
  end

  it 'should terminate' do
    agent = TestAgent.start(@space)

    # wait to start agent activity
    agent.wait_until_after(:test)

    # write terminate command
    write(Tuple[:command].new(name: "terminate", args: []))

    # wait terminate process
    agent.wait_until_terminated

    # test
    agent.should.be.terminated
  end
end
