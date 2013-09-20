module Pione
  module Tuple
    # TaskTuple is a class for rule application job with inputs, outpus and parameters.
    class TaskTuple < BasicTuple
      define_format [:task,
        # digest
        [:digest, String],
        # package id
        [:package_id, String],
        # rule name
        [:rule_name, String],
        # input data list
        [:inputs, Array],
        # parameter list
        [:param_set, Lang::ParameterSet],
        # request features
        [:features, Lang::FeatureSequence],
        # task domain id
        [:domain_id, String],
        # domain id of the caller
        [:caller_id, String]
      ]
    end
  end
end
