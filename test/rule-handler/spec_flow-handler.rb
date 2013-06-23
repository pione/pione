require_relative '../test-util'

location = Location[File.dirname(__FILE__)] + "spec_flow-handler.pione"
$doc = Component::Document.load(location)

describe 'Pione::RuleHandler::FlowRule' do
  before do
    @ts = create_tuple_space_server
    @rule = $doc.find('Test')
    write(Tuple[:rule].new('&Main:Shell', $doc.find('Shell')))

    location = Location[Temppath.create]
    location_a = location + "1.a"
    location_b = location + "1.b"
    location_a.create("1")
    location_b.create("2")

    @tuple_a = Tuple[:data].new(domain: "Main_Test", name: '1.a', location: location_a, time: Time.now)
    @tuple_b = Tuple[:data].new(domain: "Main_Test", name: '1.b', location: location_b, time: Time.now)

    @tuples = [@tuple_a, @tuple_b]
    @tuples.each {|t| write(t) }

    @handler = @rule.make_handler(@ts, @tuples, Parameters.empty, [], domain: 'Main_Test')
  end

  after do
    @ts.terminate
  end

  it "should have inputs" do
    @handler.inputs.should.include @tuple_a
    @handler.inputs.should.include @tuple_b
  end

  it "should have empty outputs before executing" do
    @handler.outputs.should.empty
  end

  it "should have base-location" do
    @handler.base_location.should == @ts.base_location
  end

  it "should have domain" do
    @handler.domain.should == "Main_Test"
  end

  it "should execute a flow" do
    thread = Thread.new { @handler.execute }
    task = read(Tuple[:task].new)
    task.rule_path.should == '&Main:Shell'
    task.inputs.map{|d| d.name}.sort.should == ['1.a', '1.b']
    task_worker = Agent[:task_worker].start(@ts)
    thread.join
    output = @handler.outputs.first
    output.name.should == '1.c'
    should.not.raise do
      read(Tuple[:data].new(name: '1.c', domain: @handler.domain))
    end
  end
end
