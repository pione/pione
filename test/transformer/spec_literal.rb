require 'pione/test-util'

describe 'Transformer::Literal' do
  describe 'data_name' do
    it 'should get strings' do
      data = {
        "'abc'" => 'abc',
        "'a\\bc'" => 'abc',
        "'a\\''" => "a'",
        "'a\\\"'" => "a\""
      }
      data.each do |string, val|
        res = Transformer.new.apply(Parser.new.data_name.parse(string))
        res.should == val
      end
    end
  end

  describe 'feature_name' do
    it 'should get feature expressions' do
      data = {
        '+abc' => FeatureExpr.new('abc', :requisite),
        '-abc' => FeatureExpr.new('abc', :exclusive),
        '?abc' => FeatureExpr.new('abc', :preferred)
      }
      data.each do |string, expected|
        res = Transformer.new.apply(Parser.new.feature_name.parse(string))
        res.should == expected
      end
    end
  end

  describe 'string' do
    it 'should get strings' do
      data = {
        '"abc"' => 'abc',
        '"a\bc"' => 'abc',
        '"a\'"' => 'a\'',
        '"a\""' => 'a"'
      }
      data.each do |string, expected|
        res = Transformer.new.apply(Parser.new.string.parse(string))
        res.should == expected
      end
    end
  end

  describe 'integer' do
    it 'should get integers' do
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
        res = Transformer.new.apply(Parser.new.integer.parse(string))
        res.should == expected
      end
    end
  end

  describe 'float' do
    it 'should get floats' do
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
        res = Transformer.new.apply(Parser.new.float.parse(string))
        res.should == expected
      end
    end
  end

end
