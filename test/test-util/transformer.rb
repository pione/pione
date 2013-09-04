module TestUtil
  module Transformer
    # transformer interface for bacon contexts.
    module Interface
      # Start transformer spec context.
      def transformer_spec(name, parser_name, option={}, &b)
        TestUtil::Transformer.spec(name, parser_name, option, self, &b)
      end
    end

    # test case
    class TestCase < StructX
      member :string
      member :expected
    end

    # succeed case
    class SucceedCase < StructX
      member :string
    end

    # fail case
    class FailCase < StructX
      member :string
      member :exception_type
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

      def succeed(string)
        push(SucceedCase.new(string))
      end

      def fail(string, exception_type)
        push(FailCase.new(string, exception_type))
      end
    end

    class Spec
      forward_as_key! :@option, :parser_class, :transformer_class, :package_name, :filename

      def initialize(testcases, name, parser_name, option, context)
        @testcases = testcases
        @name = name
        @parser_name = parser_name
        @option = Hash.new
        @option[:parser_class] = option[:parser_class] || Pione::Parser::DocumentParser
        @option[:transformer_class] = option[:transformer_class] || Pione::Transformer::DocumentTransformer
        @option[:package_name] = option[:package_name] || "Test"
        @option[:filename] = option[:filename] || "Test"
        @context = context
      end

      # declare specitification in the context
      def declare
        @testcases.each do |tc|
          case tc
          when Naming::Eq, Naming::Block
            test_case(tc)
          when SucceedCase
            succeed_case(tc)
          when FailCase
            fail_case(tc)
          end
        end
      end

      private

      def parse(string)
        # cut indentations
        string = Util::Indentation.cut(string)
        parser = parser_class.new.send(@parser_name).parse(string)
        transformer_class.new.apply(parser, package_name: package_name, filename: filename)
      end

      # declare by TestCase
      def test_case(tc)
        string = tc.value.string
        expected = tc.value.expected
        res = parse(string)
        msg = "should get %s:%s%s"
        msg_args = [@name, string.include?("\n") ? "\n" : " ", string.chomp]

        @context.it(msg % msg_args) do
          case tc
          when Naming::Eq
            res.should == expected
          when Naming::Block
            expected.call(res)
          end
        end
      end

      # declare by SucceedCase
      def succeed_case(tc)
        block = Proc.new {parse(tc.string)}
        msg = "should succeed in %s transformation:%s%s"
        msg_args = [@name, tc.string.include?("\n") ? "\n" : " ", tc.string.chomp]

        @context.it(msg % msg_args) { should.not.raise(&block) }
      end

      # declare by FailCase
      def fail_case(tc)
        block = Proc.new {parse(tc.string)}
        msg = "should fail in %s transformation with %s:%s%s"
        msg_args = [@name, tc.exception_type, tc.string.include?("\n") ? "\n" : " ", tc.string.chomp]

        @context.it(msg % msg_args) { should.raise(tc.exception_type, &block) }
      end
    end

    class << self
      # Define transformer specification.
      def spec(name, parser_name, option={}, context, &b)
        testcases = TestCases.new.tap {|x| x.instance_eval(&b)}

        # setup bacon context
        context.describe(name) do
          Spec.new(testcases, name, parser_name, option, context).declare
        end
      end
    end
  end
end
