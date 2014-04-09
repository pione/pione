# UpdateCriteria repesents rule application criteria.
module Pione
  module RuleEngine
    module UpdateCriteria
      class << self
        # Return true if the rule has no output conditions.
        def no_output_conditions?(env, rule_condition, inputs, outputs, data_null_tuples)
          rule_condition.outputs.empty?
        end

        # Return true if data tuples don't exist against output conditions with
        # write operation.
        def not_exist_output_data?(env, rule_condition, inputs, outputs, data_null_tuples)
          result = false
          rule_condition.outputs.each_with_index do |condition, i|
            _condition = condition.eval(env)
            if _condition.operation == :write or _condition.operation == :touch
              # FIXME : each tuples are empty or single data tuple, this is confusing
              case _condition.distribution
              when :all
                if outputs[i].nil? or outputs[i].select{|data| _condition.match(data.name)}.empty?
                  unless _condition.accept_nonexistence? and data_null_tuples.any?{|tuple| tuple.position == i}
                    result = true
                  end
                end
              when :each
                if outputs[i].nil? or (outputs[i].kind_of?(Array) and outputs[i].empty?) or not(_condition.match(outputs[i][0].name))
                  unless _condition.accept_nonexistence? and data_null_tuples.any?{|tuple| tuple.position == i}
                    result = true
                  end
                end
              end
            end
            break if result
          end
          return result
        end

        # Return true if data tuples exist against output conditions with remove
        # or touch operation.
        def exist_output_data?(env, rule_condition, inputs, outputs, data_null_tuples)
          result = false
          rule_condition.outputs.each_with_index do |condition, i|
            _condition = condition.eval(env)
            # remove
            if _condition.operation == :remove
              case _condition.distribution
              when :all
                if not(outputs[i].nil? or outputs[i].select{|data| _condition.match(data.name)}.empty?)
                  result = true
                end
              when :each
                if not(outputs[i].nil?) and _condition.match(outputs[i].first.name)
                  result = true
                end
              end
            end
            break if result
          end
          return result
        end

        # Return true if newer input data exist.
        def exist_newer_input_data?(env, rule_condition, inputs, outputs, data_null_tuples)
          # get output oldest time
          outputs = outputs.select.with_index do |output, i|
            rule_condition.outputs[i].eval(env).update_criteria == :care
          end
          # output_oldest_time = outputs.flatten.map{|output| output.time}.sort.first
          output_last_time = outputs.flatten.map{|output| output.time}.sort.last

          # get input last time
          inputs = inputs.select.with_index do |input, i|
            rule_condition.inputs[i].eval(env).update_criteria == :care
          end
          input_last_time = inputs.flatten.map{|input| input.time}.sort.last

          # special touch criterion
          rule_condition.outputs.each_with_index do |condition, i|
            _condition = condition.eval(env)
            if _condition.operation == :touch
              if inputs.flatten.select{|t| _condition.match(t.name)}.size > 0
                return true
              end
            end
          end

          # criteria
          #return false unless output_oldest_time
          return false unless output_last_time
          return false unless input_last_time
          #return output_oldest_time < input_last_time
          return output_last_time < input_last_time
        end

        # Return update order name if we need to update.
        def order(env, rule_condition, inputs, outputs, data_null_tuples)
          if FORCE_UPDATE.any? {|name| self.send(name, env, rule_condition, inputs, outputs, data_null_tuples)}
            return :force
          end
          if WEAK_UPDATE.any? {|name| self.send(name, env, rule_condition, inputs, outputs, data_null_tuples)}
            return :weak
          end
        end

        # force update criteria
        FORCE_UPDATE = [:no_output_conditions?, :exist_newer_input_data?]

        # update criteria
        WEAK_UPDATE = [:not_exist_output_data?, :exist_output_data?]
      end
    end
  end
end
