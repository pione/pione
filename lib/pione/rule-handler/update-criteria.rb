# UpdateCriteria repesents rule application criteria.
module Pione
  module RuleHandler
    module UpdateCriteria
      class << self
        # Return true if the rule has no output conditions.
        #
        # @param rule [Rule]
        #   rule
        # @param inputs [Tuple::Data]
        #   input data tuples
        # @param outputs [Tuple::Data]
        #   output data tuples
        # @param vtable [VariableTable]
        #   variable table
        # @return [Boolean]
        #   true if the rule has no output conditions
        def no_output_conditions?(rule, inputs, outputs, vtable)
          rule.outputs.empty?
        end

        # Return true if data tuples don't exist against output conditions with
        # write operation.
        #
        # @param rule [Rule]
        #   rule
        # @param inputs [Tuple::Data]
        #   input data tuples
        # @param outputs [Tuple::Data]
        #   output data tuples
        # @param vtable [VariableTable]
        #   variable table
        # @return [Boolean]
        #   true if data tuples don't exist against output conditions with write
        #   operation
        def not_exist_output_data?(rule, inputs, outputs, vtable)
          result = false
          rule.outputs.each_with_index do |data_expr, i|
            data_expr = data_expr.eval(vtable)
            if data_expr.write?
              case data_expr.modifier
              when :all
                if outputs[i].nil? or outputs[i].select{|data| data_expr.match(data.name)}.empty?
                  result = true
                end
              when :each
                if outputs[i].nil? or not(data_expr.match(outputs[i].name))
                  result = true
                end
              end
            end
            break if result
          end
          return result
        end


        # Return true if data tuples exist against output conditions with remove
        # or touch operation.
        #
        # @param rule [Rule]
        #   rule
        # @param inputs [Tuple::Data]
        #   input data tuples
        # @param outputs [Tuple::Data]
        #   output data tuples
        # @param vtable [VariableTable]
        #   variable table
        # @return [Boolean]
        #   if data tuples exist against output conditions with remove or touch
        #   operation
        def exist_output_data?(rule, inputs, outputs, vtable)
          result = false
          rule.outputs.each_with_index do |data_expr, i|
            data_expr = data_expr.eval(vtable)
            if data_expr.remove? or data_expr.touch?
              case data_expr.modifier
              when :all
                if not(outputs[i].select{|data| data_expr.match(data.name)}.empty?)
                  result = true
                end
              when :each
                if data_expr.match(outputs[i].name)
                  result = true
                end
              end
            end
            break if result
          end
          return result
        end

        # Return true if newer input data exist.
        #
        # @param rule [Rule]
        #   rule
        # @param inputs [Tuple::Data]
        #   input data tuples
        # @param outputs [Tuple::Data]
        #   output data tuples
        # @param vtable [VariableTable]
        #   variable table
        # @return [Boolean]
        #   true if newer input data exist
        def exist_newer_input_data?(rule, inputs, outputs, vtable)
          # get output oldest time
          outputs = outputs.select.with_index{|output, i| rule.outputs[i].eval(vtable).care?}
          output_oldest_time = outputs.flatten.map{|output| output.time}.sort.first

          # get input last time
          inputs = inputs.select.with_index{|input, i| rule.inputs[i].eval(vtable).care?}
          input_last_time = inputs.flatten.map{|input| input.time}.sort.last

          #p output_oldest_time
          #p input_last_time

          # criteria
          return false unless output_oldest_time
          return false unless input_last_time
          return output_oldest_time < input_last_time
        end

        # Return update order name if we need to update.
        #
        # @param [Rule] rule
        #   rule
        # @param [Tuple::DataTuple] inputs
        #   input tuples
        # @param [Tuple::DataTuple] outputs
        #   output tuples
        # @param [VariableTable] vtable
        #   variable table
        # @return [Symbol,nil]
        #   update order or nil
        def order(rule, inputs, outputs, vtable)
          if FORCE_UPDATE.any? {|name| self.send(name, rule, inputs, outputs, vtable)}
            return :force
          end
          if WEAK_UPDATE.any? {|name| self.send(name, rule, inputs, outputs, vtable)}
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
