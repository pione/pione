module Pione
  module TestHelper
    module Parser
      # Make a test parser class by the sub-parser module.
      def make_test_parser(parser_module)
        klass = Class.new(Parslet::Parser)
        klass.instance_eval do
          include parser_module
        end
        return klass
      end
      module_function :make_test_parser

      # Make specifications of parser.
      def spec(rb, context, parser=Pione::Lang::DocumentParser)
        basename = File.basename(rb, ".rb")
        path = File.join(File.dirname(rb), "data", basename[5..-1] + ".yml")
        YAML.load(File.read(path)).each do |name, testcase|
          context.describe name do
            if strings = testcase["valid"]
              strings.each do |string|
                it "should parse as %s:%s%s" % [name, string.include?("\n") ? "\n" : " ", string.chomp] do
                  should.not.raise(Parslet::ParseFailed) do
                    parser.new.send(name).parse(string)
                  end
                end
              end
            end

            if strings = testcase["invalid"]
              strings.each do |string|
                it "should fail when parsing as %s:%s%s" % [name, string.include?("\n") ? "\n" : " ", string.chomp] do
                  should.raise(Parslet::ParseFailed) do
                    parser.new.send(name).parse(string)
                  end
                end
              end
            end
          end
        end
      end
      module_function :spec
    end
  end
end
