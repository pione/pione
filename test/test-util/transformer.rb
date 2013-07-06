module TestUtil
  module Transformer
    class TestCase < StructX
      member :string
      member :expected
    end

    class TestCaseEq < StructX
      member :string
      member :expected
    end

    def spec(name, parser, context, &b)
      testcases = Array.new

      def testcases.tc(obj)
        case obj
        when Hash
          obj.each do |key, val|
            push(TestCaseEq.new(key, val))
          end
        else
          push(TestCaseEq.new(obj, yield))
        end
      end

      def testcases.transform(obj, &b)
        push(TestCase.new(obj, b))
      end

      def testcases.test(obj, res=nil, &b)
        if res
          push(TestCaseEq.new(obj, res))
        else
          push(TestCase.new(obj, b))
        end
      end

      testcases.instance_eval(&b)
      context.describe name do
        testcases.each do |tc|
          it "should get %s:%s%s" % [name, tc.string.include?("\n") ? "\n" : " ", tc.string.chomp] do
            res = DocumentTransformer.new.apply(
              DocumentParser.new.send(parser).parse(tc.string)
            )
            case tc
            when TestCaseEq
              res.should == tc.expected
            when TestCase
              tc.expected.call(res)
            end
          end
        end
      end
    end
    module_function :spec
  end
end
