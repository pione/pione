require 'pione/common'

module Pione
  # UpdateCriteria repesents rule application criteria.
  module UpdateCriteria
    # Return true if we need to update because of no output rule.
    def self.no_output_rules?(rule, inputs, outputs, vtable)
      rule.outputs.empty?
    end

    # Return true if we need to update because of lacking some ouputs.
    def self.not_exist_output?(rule, inputs, outputs, vtable)
      return true if outputs.empty?
      result = false
      rule.outputs.each_with_index do |data_expr, i|
        data_expr = data_expr.eval(vtable)
        case data_expr.modifier
        when :all
          if outputs[i].select{|data| data_expr.match(data.name)}.empty?
            result = true
          end
        when :each
          unless data_expr.match(outputs[i].name)
            result = true
          end
        end
        break if result
      end
      return result
    end

    # Return true if we need to update because of newer inputs.
    def self.exist_newer_input?(rule, inputs, outputs, vtable)
      # get output oldest time
      output_oldest_time = outputs.flatten.map{|out|out.time}.sort.last

      # get input last time
      input_last_time = inputs.flatten.map{|input|input.time}.sort.first

      # criteria
      return false unless output_oldest_time
      return false unless input_last_time
      return output_oldest_time < input_last_time
    end

    # Return true if we need to update.
    def self.satisfy?(rule, inputs, outputs, vtable)
      CRITERIAS.any?{|name| self.send(name, rule, inputs, outputs, vtable)}
    end

    CRITERIAS = [ :no_output_rules?,
                  :not_exist_output?,
                  :exist_newer_input? ]
  end
end
