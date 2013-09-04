require_relative '../test-util'

describe 'Pione::Transformer::DocumentTransformer' do
  it "should transform" do
    parser = Pione::Parser::DocumentParser.new.parse("$X := 1")
    opts = {package_name: "Test", filename: "Test"}
    context = Pione::Transformer::DocumentTransformer.new.apply(parser, opts)
    context.should.kind_of(Lang::PackageContext)
  end
end
