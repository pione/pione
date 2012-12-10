module Pione
  module Tuple
    # RequestRuleTuple represents task worker's request for rule-provider.
    class RequestRuleTuple < BasicTuple
    #   rule_path : rule location path
    define_format [:request_rule, :rule_path]
    end
  end
end
