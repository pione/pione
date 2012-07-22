require 'pione/common'

module Pione
  # UpdateCriteria repesents rule application criteria.
  module UpdateCriteria
    # Return true if we need to update because of no output rule.
    def self.no_output_rules?(rule, inputs, outputs)
      rule.outputs.empty?
    end

    # Return true if we need to update because of lacking some ouputs.
    def self.not_exist_output?(rule, inputs, outputs)
      return true if outputs.empty?
      rule.outputs.size != outputs.size
    end

    # Return true if we need to update because of newer inputs.
    def self.exist_newer_input?(rule, inputs, outputs)
      # get output oldest time
      output_oldest_time = outputs.flatten.map{|out|out.time}.sort.last

      # get input last time
      input_last_time = inputs.flatten.map{|input|input.time}.sort.first

      # criteria
      return output_oldest_time < input_last_time
    end

    # Return true if we need to update.
    def self.satisfy?(rule, inputs, outputs)
      CRITERIAS.any?{|name| self.send(name, rule, inputs, outputs)}
    end

    CRITERIAS = [ :no_output_rules?,
                  :not_exist_output?,
                  :exist_newer_input? ]
  end
end
