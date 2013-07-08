module TestUtil
  # Test pione method.
  def test_pione_method(name)
    yamlname = 'spec_%s.yml' % name
    ymlpath = File.join(File.dirname(__FILE__), "..", 'model', yamlname)
    testcases = YAML.load_file(ymlpath)

    describe "pione method test cases" do
      testcases.each do |title, cases|
        describe title do
          cases.each do |testcase|
            expect = testcase.keys.first
            expr = testcase[expect].to_s
            expect = expect.to_s
            vtable = VariableTable.new

            it '%s should be %s' % [expr, expect] do
              expect = DocumentTransformer.new.apply(DocumentParser.new.expr.parse(expect))
              expr = DocumentTransformer.new.apply(DocumentParser.new.expr.parse(expr))
              expect.eval(vtable).should == expr.eval(vtable)
            end
          end
        end if cases
      end
    end
  end
end
