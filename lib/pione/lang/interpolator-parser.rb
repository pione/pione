module Pione
  module Lang
    # InterpolatorParser is a parser for handling embeded expression in strings.
    class InterpolatorParser < Parslet::Parser
      include Util::ParsletParserExtension
      include CommonParser
      include LiteralParser
      include ExprParser

      #
      # root
      #
      root(:interpolators)

      # +interpolator+ matches interpolation parts.
      rule(:interpolator) { embeded_variable | embeded_expr | narrative }
      rule(:interpolators) { interpolator.repeat.as(:interpolators) }

      # +embeded_variable+ matches embeded expressions with variable heading.
      rule(:embeded_variable) {
        start_embeded_variable >> padded?(expr!).as(:embeded_expr) >> end_embeded_variable!
      }
      rule(:start_embeded_variable) { str("{") >> variable.present? }
      rule(:end_embeded_variable) { str("}") }
      rule(:end_embeded_variable!) { end_embeded_variable.or_error("should be '}'") }

      # +embeded_expr+ matches arbitrary embeded expressions.
      rule(:embeded_expr) {
        start_embeded_expr >> padded?(expr!).as(:embeded_expr) >> end_embeded_expr!
      }
      rule(:start_embeded_expr) { str("<?") }
      rule(:end_embeded_expr) { str("?>") }
      rule(:end_embeded_expr!) { end_embeded_expr.or_error("should be '?>'") }

      # +start_symbol+ matches start symbols of embeded expressions.
      rule(:start_symbol) { start_embeded_variable | start_embeded_expr }

      # +narrative+ matches other than embeded expressions.
      rule(:narrative) {
        (start_symbol.absent? >> any).repeat(1).as(:narrative)
      }
    end
  end
end
