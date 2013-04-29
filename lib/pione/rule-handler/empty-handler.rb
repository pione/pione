module Pione
  module RuleHandler
    class EmptyHandler < BasicHandler
      def execute
        find_outputs
      end

      # Find outputs from the domain.
      #
      # @return [void]
      def find_outputs
        tuples = read_all(Tuple[:data].new(domain: @domain))
        @rule.outputs.each_with_index do |output, i|
          output = output.eval(@variable_table)
          case output.modifier
          when :all
            @outputs[i] = tuples.find_all {|data| output.match(data.name)}
          when :each
            # FIXME
            @outputs[i] = tuples.find {|data| output.match(data.name)}
          end
        end
      end
    end
  end
end
