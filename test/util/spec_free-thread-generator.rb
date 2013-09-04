require_relative "../test-util"

describe "Pione::Util::FreeThreadGenerator" do
  it "should get a thread in safety" do
    array = Array.new
    group = ThreadGroup.new

    # generate threads
    100.times {|i| group.add(Util::FreeThreadGenerator.generate{sleep 1; array[i] = i})}

    # wait
    group.list.each {|thread| thread.join}

    # test
    100.times {|i| array[i].should == i}
  end

  it "should escape thread group encloser" do
    group = ThreadGroup.new

    thread = Thread.new do
      Thread.stop # wait to be in the thread group
      Thread.current.group.should == group

      # child thread
      child_thread = Thread.new {}
      child_thread.group.should == group

      # test
      free_thread = FreeThreadGenerator.generate {}
      free_thread.group.should == ThreadGroup::Default
    end

    # push the thread into group
    group.add(thread)

    # restart the thread
    sleep 1 while not(thread.stop?)
    thread.run
    thread.join
  end
end
