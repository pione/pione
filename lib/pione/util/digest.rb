module Pione
  module Util
    module TaskDigest
      def generate(package_id, rule_name, inputs, param_set)
        case inputs.flatten.size
        when 0
          _inputs = ""
        when 1, 2, 3
          _inputs = inputs.flatten.map{|t| t.name}.join(",")
        else
          _inputs = "%s,..." % inputs.flatten[0..2].map{|i| i.name}.join(",")
        end
        _param_set = param_set.filter(["I", "INPUT", "O", "OUTPUT", "*"])
        _param_set = _param_set.map{|k,v| "%s:%s" % [k, v.textize]}.join(",")
        "&%s:%s([%s],{%s})" % [package_id, rule_name, _inputs, _param_set]
      end
      module_function :generate
    end
  end
end
