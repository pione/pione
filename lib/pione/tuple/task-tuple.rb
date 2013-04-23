module Pione
  module Tuple
    # TaskTuple is a class for rule application job with inputs, outpus and parameters.
    class TaskTuple < BasicTuple
      define_format [:task,
        # rule location path
        [:rule_path, String],
        # input data list
        [:inputs, Array],
        # parameter list
        [:params, Model::Parameters],
        # request features
        [:features, Model::Feature::Expr],
        # task domain
        [:domain, String],
        # call stack(domain list)
        [:call_stack, Array]
      ]

      # Returns the digest string of the task.
      # @return [String]
      #   task digest string
      def digest
        "%s([%s],{%s})" % [
          rule_path,
          inputs.map{|i|
            if i.kind_of?(Array)
              i.empty? ? "[]" : "[%s, ...]" % i[0].name
            else
              i.name
            end
          }.join(","),
          params.data.select{|k,_|
            not(k.toplevel?)
          }.map{|k,v| "%s:%s" % [k.name, v.textize]}.join(",")
        ]
      end
    end
  end
end
