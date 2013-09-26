require 'pione/test-helper'

describe 'Pione::Transformer::InterpolatorTransformer' do
  opts = {
    parser_class: Lang::InterpolatorParser,
    transformer_class: Lang::InterpolatorTransformer
  }

  transformer_spec("embeded_variable", :embeded_variable, opts) do
    test("{$x}", TestHelper::Lang.expr("$x"))
    test("{$x.as_string}", TestHelper::Lang.expr("$x.as_string"))
    test("{$x.m(A, 1, true)}", TestHelper::Lang.expr("$x.m(A, 1, true)"))
    test("{$x + $y}", TestHelper::Lang.expr("$x + $y"))
  end
end
