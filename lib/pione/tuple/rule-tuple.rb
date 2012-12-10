module Pione
  module Tuple
    # RuleTuple represents rule content.
    class RuleTuple < BasicTuple
      #   rule_path : rule location path
      #   content   : rule content
      define_format [:rule, :rule_path, :content, :status]
    end
  end
end
