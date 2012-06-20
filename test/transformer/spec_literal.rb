require 'pione/test-util'

describe 'Transformer::Literal' do
  describe 'data_name' do
    data = {
      "'abc'" => 'abc',
      "'a\\bc'" => 'abc',
      "'a\\''" => "a'",
      "'a\\\"'" => "a\""
    }
    data.each do |string, val|
      it "should get strings: #{string}" do
        res = Transformer.new.apply(Parser.new.data_name.parse(string))
        res.should == val
      end
    end
  end

  describe 'package_name' do
    data = {
      "&abc" => Model::Package.new('abc'),
      "&ABC" => Model::Package.new('ABC'),
    }
    data.each do |string, val|
      it "should get strings: #{string}" do
        res = Transformer.new.apply(Parser.new.data_name.parse(string))
        res.should == val
      end
    end
  end

  describe 'string' do
    data = {
      '"abc"' => 'abc',
      '"a\bc"' => 'abc',
      '"a\'"' => 'a\'',
      '"a\""' => 'a"'
    }
    data.each do |string, expected|
      it "should get pione strings: #{string}" do
        res = Transformer.new.apply(Parser.new.string.parse(string))
        res.should == PioneString.new(expected)
      end
    end
  end

  describe 'integer' do
    data = {
      '1' => 1,
      '123' => 123,
      '01' => 1,
      '000123' => 123,
      '-1' => -1,
      '-01' => -1,
      '+1' => 1,
      '+01' => 1
    }
    data.each do |string, expected|
      it "should get integers: #{string}" do
        res = Transformer.new.apply(Parser.new.integer.parse(string))
        res.should == PioneInteger.new(expected)
      end
    end
  end

  describe 'float' do
    data = {
      '0.1' => 0.1,
      '123.1' => 123.1,
      '01.23' => 1.23,
      '000123.456' => 123.456,
      '-1.2' => -1.2,
      '-01.1' => -1.1,
      '+1.9' => 1.9,
      '+01.8' => 1.8
    }
    data.each do |string, expected|
      it "should get floats: #{string}" do
        res = Transformer.new.apply(Parser.new.float.parse(string))
        res.should == PioneFloat.new(expected)
      end
    end
  end

  #describe 'rule_name'

end
