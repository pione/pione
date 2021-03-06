require 'pione/test-helper'

#
# test cases
#
yamlname = 'spec_data-finder.yml'
ymlpath = File.join(File.dirname(__FILE__), yamlname)
testcases = YAML.load_file(ymlpath)

describe 'Pione::RuleEngine::DataFinder' do
  before do
    @space = TestHelper::TupleSpace.create(self)
    @env = TestHelper::Lang.env
  end

  after do
    @space.terminate
  end

  it 'should find a data tuple by complete name' do
    tuples = [
      TupleSpace::DataTuple.new('test', '1.a', nil, Time.now),
      TupleSpace::DataTuple.new('test', '2.a', nil, Time.now),
      TupleSpace::DataTuple.new('test', '3.a', nil, Time.now)
    ]
    tuples.each {|t| write(t) }
    finder = RuleEngine::DataFinder.new(tuple_space_server, 'test')
    finder.send(:find_tuples_by_condition, '1.a').should == [tuples.first]
  end

  it 'should find data tuples by incomplete name' do
    tuples = [
      TupleSpace::DataTuple.new('test', '1.a', nil, Time.now),
      TupleSpace::DataTuple.new('test', '2.a', nil, Time.now),
      TupleSpace::DataTuple.new('test', '3.a', nil, Time.now)
    ]
    tuples.each {|t| write(t) }
    finder = RuleEngine::DataFinder.new(tuple_space_server, 'test')
    res = finder.send(:find_tuples_by_condition, Lang::DataExprSequence.of('*.a'))
    tuples.each {|t| res.should.include t }
  end

  it 'should find no data' do
    tuple = TupleSpace::DataTuple.new('test', '2.a', nil, Time.now)
    tuple_space_server.write(tuple)
    finder = RuleEngine::DataFinder.new(tuple_space_server, 'test')
    finder.send(:find_tuples_by_condition, '1.a').should.empty
  end

  it 'should find in the domain' do
    tuple = TupleSpace::DataTuple.new('other', '1.a', nil, Time.now)
    tuple_space_server.write(tuple)
    finder = RuleEngine::DataFinder.new(tuple_space_server, 'test')
    finder.send(:find_tuples_by_condition, '1.a').should.empty
  end

  testcases.each do |testname, testcase|
    it "should find input combination: #{testname}" do
      finder = RuleEngine::DataFinder.new(tuple_space_server, 'test')

      # tuples
      testcase['tuples'].map {|name|
        TupleSpace::DataTuple.new(name: name, domain: 'test', location: Location[name])
      }.each do |tuple|
        write(tuple)
      end

      # query
      query = testcase['query'].map {|d|
        if d.kind_of?(Hash)
          modifier = d["modifier"] == "all" ? :all : :each
          DataExpr.new(d["name"], modifier)
        else
          TestHelper::Lang.expr!(@env, d)
        end
      }

      # results
      results = testcase['results'].map {|res|
        res.map {|name|
          if name.kind_of?(Array)
            name.map {|n| TupleSpace::DataTuple.new(name: n, domain: 'test', location: Location[n]) }
          else
            TupleSpace::DataTuple.new(name: name, domain: 'test', location: Location[name])
          end
        }
      }

      # test
      enum = finder.to_enum(:find, :input, query, @env)
      enum.to_a.map{|env, combination| combination }.should == results
    end
  end
end
