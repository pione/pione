module Pione
  class Parser
    module Literal
      include Parslet
      include Common

      # data_name
      rule(:data_name) {
        squote >>
        (backslash >> any | squote.absent? >> any).repeat.as(:data_name) >>
        squote
      }

      # identifier
      rule(:identifier) {
        ((space | symbols | line_end).absent? >> any).repeat(1)
      }

      # variable
      rule(:variable) {
        doller >>
        identifier.as(:variable)
      }

      # rule_name
      rule(:rule_name) {
        ( slash.maybe >>
          identifier >>
          (slash >> identifier).repeat(0)
          ).as(:rule_name)
      }

      # package_name
      rule(:package_name) {
        identifier.as(:package_name)
      }

      # string
      rule(:string) {
        dquote >>
        (backslash >> any | dquote.absent? >> any).repeat.as(:string) >>
        dquote
      }

      # integer
      rule(:integer) {
        ( match('[+-]').maybe >>
          digit.repeat(1)
          ).as(:integer)
      }

      # float
      rule(:float) {
        ( match('[+-]').maybe >>
          digit.repeat(1) >>
          dot >>
          digit.repeat(1)
          ).as(:float)
      }
    end
  end
end
