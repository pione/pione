require 'pione/test-helper'

TestHelper.scope do |this|
  class this::TestSender
    def initialize(uri)
      @targets = Global.notification_targets
      @notification = Notification::Message.new(
        "TEST_SENDER", "TEST", {"front" => uri}
      )
    end

    def send
      Notification::Transmitter.transmit(@notification, @targets)
    end
  end

  class this::TestRecipient
    include Front::NotificationRecipientInterface
    def initialize
      set_recipient()
    end
  end

  describe Pione::Agent::NotificationListener do
    before do
      @tuple_space = TestHelper::TupleSpace.create(self)
      Global.expressional_features = Util.parse_features("*")

      # broker
      @broker_model = Model::TaskWorkerBrokerModel.new
      @broker_model[:spawn_task_worker] = false
      @broker_model[:task_worker_size] = 5
      @broker = Agent::TaskWorkerBroker.start(@broker_model)

      # provider
      @provider_cmd = Command::PioneTupleSpaceProvider.new([])

      @model = Model::NotificationListenerModel.new
      @model.add_recipient("druby://localhost:0") # fake URI
      @listener = Agent::NotificationListener.new(@model, URI.parse("pnu://127.0.0.1:%s" % 12345))
    end

    after do
      @broker.terminate
      @tuple_space.terminate
      Global.expressional_features = nil
    end

    it "should run and terminate listener" do
      @listener.start
      @listener.wait_until(:receive)
      @listener.terminate
      @listener.wait_until_terminated
      @listener.should.terminated
    end

    # it "should receive messages" do
    #   @provider_cmd.run
    #   provider = Agent::TupleSpaceProvider.start(@provider_cmd.model[:front].uri)
    #   @listener.start

    #   # wait receiver to handle notification
    #   @listener.wait_until_after(:receive, 10)
    #   @listener.notification_handlers.list.each {|thread| thread.join}

    #   # test tuple spaces
    #   spaces = listener.tuple_spaces
    #   spaces.size.should == 1
    #   spaces.first.should == @tuple_space

    #   # terminate agents
    #   provider.terminate
    #   @listener.terminate
    #   provider.wait_until_terminated
    #   @listener.wait_until_terminated
    #   provider.should.terminated
    #   @listener.should.terminated
    # end
  end
end
