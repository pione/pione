require_relative '../test-util'

describe 'Pione::Transformer::InterpolatorTransformer' do
  opts = {
    parser_class: Lang::InterpolatorParser,
    transformer_class: Lang::InterpolatorTransformer
  }

  transformer_spec("embeded_variable", :embeded_variable, opts) do
    test("{$x}", TestUtil::Lang.expr("$x"))
    test("{$x.as_string}", TestUtil::Lang.expr("$x.as_string"))
    test("{$x.m(A, 1, true)}", TestUtil::Lang.expr("$x.m(A, 1, true)"))
    test("{$x + $y}", TestUtil::Lang.expr("$x + $y"))
  end
end