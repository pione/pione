module TestUtil
  module Transformer
    # test case
    class TestCase < StructX
      member :string
      member :expected
    end

    # test case list
    class TestCases < Array
      def test(obj, res=nil, &b)
        if res
          push(Naming.Eq(TestCase.new(obj, res)))
        else
          push(Naming.Block(TestCase.new(obj, b)))
        end
      end
    end

    # Define transformer specification.
    def spec(name, parser, context, &b)
      testcases = TestCases.new.tap {|x| x.instance_eval(&b)}

      # setup bacon context
      context.describe name do
        testcases.each do |tc|
          string = tc.value.string
          expected = tc.value.expected

          it "should get %s:%s%s" % [name, string.include?("\n") ? "\n" : " ", string.chomp] do
            res = DocumentTransformer.new.apply(
              DocumentParser.new.send(parser).parse(string)
            )
            case tc
            when Naming::Eq
              res.should == expected
            when Naming::Block
              expected.call(res)
            end
          end
        end
      end
    end
    module_function :spec
  end
end
