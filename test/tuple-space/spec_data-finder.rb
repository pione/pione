require_relative '../test-util'

#
# test cases
#
yamlname = 'spec_data-finder.yml'
ymlpath = File.join(File.dirname(__FILE__), yamlname)
testcases = YAML.load_file(ymlpath)

describe 'DataFinder' do
  before do
    create_tuple_space_server
  end

  after do
    #tuple_space_server.terminate
  end

  it 'should find a data tuple by complete name' do
    tuples = [
      Tuple[:data].new('test', '1.a', nil, Time.now),
      Tuple[:data].new('test', '2.a', nil, Time.now),
      Tuple[:data].new('test', '3.a', nil, Time.now)
    ]
    tuples.each {|t| tuple_space_server.write(t) }
    finder = DataFinder.new(tuple_space_server, 'test')
    finder.send(:find_by_expr, '1.a').should == [tuples.first]
  end

  it 'should find data tuples by incomplete name' do
    tuples = [
      Tuple[:data].new('test', '1.a', nil, Time.now),
      Tuple[:data].new('test', '2.a', nil, Time.now),
      Tuple[:data].new('test', '3.a', nil, Time.now)
    ]
    tuples.each {|t| tuple_space_server.write(t) }
    finder = DataFinder.new(tuple_space_server, 'test')
    res = finder.send(:find_by_expr, DataExpr.new('*.a'))
    tuples.each {|t| res.should.include t }
  end

  it 'should find no data' do
    tuple = Tuple[:data].new('test', '2.a', nil, Time.now)
    tuple_space_server.write(tuple)
    finder = DataFinder.new(tuple_space_server, 'test')
    finder.send(:find_by_expr, '1.a').should.empty
  end

  it 'should find in the domain' do
    tuple = Tuple[:data].new('other', '1.a', nil, Time.now)
    tuple_space_server.write(tuple)
    finder = DataFinder.new(tuple_space_server, 'test')
    finder.send(:find_by_expr, '1.a').should.empty
  end

  testcases.each do |testname, testcase|
    it "should find input combination: #{testname}" do
      finder = DataFinder.new(tuple_space_server, 'test')

      # tuples
      testcase['tuples'].map {|name|
        Tuple[:data].new(name: name, domain: 'test', location: Location[name])
      }.each do |tuple|
        tuple_space_server.write(tuple)
      end

      # query
      query = testcase['query'].map {|d|
        if d.kind_of?(Hash)
          modifier = d["modifier"] == "all" ? :all : :each
          DataExpr.new(d["name"], modifier)
        else
          DocumentTransformer.new.apply(
            DocumentParser.new.expr.parse(d)
          )
        end
      }

      # results
      results = testcase['results'].map {|res|
        res.map {|name|
          if name.kind_of?(Array)
            name.map {|n| Tuple[:data].new(name: n, domain: 'test', location: Location[n]) }
          else
            Tuple[:data].new(name: name, domain: 'test', location: Location[name])
          end
        }
      }

      # test
      finder.find(:input,  query, VariableTable.new).map{|r| r.combination }.should == results
    end
  end
end
