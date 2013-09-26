require 'pione/test-helper'

describe 'Pione::Transformer::DocumentTransformer' do
  it "should transform" do
    parser = Pione::Lang::DocumentParser.new.parse("$X := 1")
    opts = {package_name: "Test", filename: "Test"}
    context = Pione::Lang::DocumentTransformer.new.apply(parser, opts)
    context.should.kind_of(Lang::PackageContext)
  end
end
