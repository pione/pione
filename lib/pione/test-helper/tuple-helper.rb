module Pione
  module TestHelper
    module Tuple
      def self.task(package_id, rule_name, inputs, param_set=nil, features=nil, caller_id='root')
        param_set = Pione::Lang::ParameterSet.new unless param_set
        features = Pione::Lang::FeatureSequence.new unless features
        digest = Util::TaskDigest.generate(package_id, rule_name, inputs, param_set)
        domain_id = Util::DomainID.generate(package_id, rule_name, inputs, param_set)
        Pione::TupleSpace::TaskTuple.new(digest, package_id, rule_name, inputs, param_set, features, domain_id, caller_id)
      end
    end
  end
end
