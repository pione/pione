module TestUtil
  # Test pione method.
  def test_pione_method(name, option={})
    yamlname = 'spec_%s.yml' % name
    ymlpath = File.join(File.dirname(__FILE__), "..", 'model', yamlname)
    testcases = YAML.load_file(ymlpath)

    transformer_option = {}
    transformer_option[:package_name] = option[:package_name] || "Test"
    transformer_option[:filename] = option[:filename] || "Test.pione"

    describe "pione method test cases" do
      testcases.each do |title, cases|
        describe title do
          cases.each do |testcase|
            expect = testcase.keys.first
            expr = testcase[expect].to_s
            expect = expect.to_s
            env = TestUtil::Lang.env

            it '%s should be %s' % [expr, expect] do
              expect = DocumentTransformer.new.apply(DocumentParser.new.expr.parse(expect), transformer_option)
              expr = DocumentTransformer.new.apply(DocumentParser.new.expr.parse(expr), transformer_option)
              expr.eval(env).should == expect.eval(env)
            end
          end
        end if cases
      end
    end
  end
end
