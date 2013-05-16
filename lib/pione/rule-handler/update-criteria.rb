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
        # @param data_null_tuples [Array<Tuple::DataNullTuple>]
        #   DataNull tuples in the domain
        # @return [Boolean]
        #   true if the rule has no output conditions
        def no_output_conditions?(rule, inputs, outputs, vtable, data_null_tuples)
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
        # @param data_null_tuples [Array<Tuple::DataNullTuple>]
        #   DataNull tuples in the domain
        # @return [Boolean]
        #   true if data tuples don't exist against output conditions with write
        #   operation
        def not_exist_output_data?(rule, inputs, outputs, vtable, data_null_tuples)
          result = false
          rule.outputs.each_with_index do |data_expr, i|
            data_expr = data_expr.eval(vtable)
            if data_expr.write? or data_expr.touch?
              # FIXME : each tuples are empty or single data tuple, this is confusing
              case data_expr.distribution
              when :all
                if outputs[i].nil? or outputs[i].select{|data| data_expr.match(data.name)}.empty?
                  unless data_expr.first.accept_nonexistence? and data_null_tuples.any?{|tuple| tuple.position == i}
                    result = true
                  end
                end
              when :each
                if outputs[i].nil? or (outputs[i].kind_of?(Array) and outputs[i].empty?) or not(data_expr.match(outputs[i].name))
                  unless data_expr.first.accept_nonexistence? and data_null_tuples.any?{|tuple| tuple.position == i}
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
        #
        # @param rule [Rule]
        #   rule
        # @param inputs [Tuple::Data]
        #   input data tuples
        # @param outputs [Tuple::Data]
        #   output data tuples
        # @param vtable [VariableTable]
        #   variable table
        # @param data_null_tuples [Array<Tuple::DataNullTuple>]
        #   DataNull tuples in the domain
        # @return [Boolean]
        #   if data tuples exist against output conditions with remove or touch
        #   operation
        def exist_output_data?(rule, inputs, outputs, vtable, data_null_tuples)
          result = false
          rule.outputs.each_with_index do |data_expr, i|
            data_expr = data_expr.eval(vtable)
            if data_expr.remove?
              case data_expr.distribution
              when :all
                if not(outputs[i].nil? or outputs[i].select{|data| data_expr.match(data.name)}.empty?)
                  result = true
                end
              when :each
                if not(outputs[i].nil?) and data_expr.match(outputs[i].name)
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
        # @param data_null_tuples [Array<Tuple::DataNullTuple>]
        #   DataNull tuples in the domain
        # @return [Boolean]
        #   true if newer input data exist
        def exist_newer_input_data?(rule, inputs, outputs, vtable, data_null_tuples)
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
        # @param inputs [Tuple::DataTuple]
        #   input tuples
        # @param outputs [Tuple::DataTuple]
        #   output tuples
        # @param vtable [VariableTable]
        #   variable table
        # @param data_null_tuples [Array<Tuple::DataNullTuple>]
        #   DataNull tuples in the domain
        # @return [Symbol,nil]
        #   update order or nil
        def order(rule, inputs, outputs, vtable, data_null_tuples)
          if FORCE_UPDATE.any? {|name| self.send(name, rule, inputs, outputs, vtable, data_null_tuples)}
            return :force
          end
          if WEAK_UPDATE.any? {|name| self.send(name, rule, inputs, outputs, vtable, data_null_tuples)}
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
