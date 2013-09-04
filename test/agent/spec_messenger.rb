require_relative '../test-util'

describe "Pione::Agent::Messenger" do
  before do
    tuple_space_server = create_tuple_space_server
    @messenger = Agent::Messenger.new(tuple_space_server)
    class << @messenger
      attr_accessor :msgs
      define_method(:puts) {|msg| @msgs << msg}
    end
    @messenger.msgs = []
  end

  after do
    @messenger.terminate
  end

  it "should take messages" do
    write(Tuple[:message].new(type: "test", head: "test", color: :green, contents: "test", level: 0))
    @messenger.start
    sleep 1
    @messenger.msgs.size.should == 1
  end
end

