module Pione
  module RuleHandler
    # RootHandler is a special handler for RootRule.
    class RootHandler < FlowHandler
      def self.message_name
        "Root"
      end

      # @api private
      def execute
        # import initial input tuples from input domain
        @inputs.flatten.each do |input|
          copy_data_into_domain(input, @domain)
        end
        # execute the rule
        result = super
        # export outputs to output domain
        @outputs.flatten.each do |output|
          copy_data_into_domain(output, '/output')
        end
        # substantiate symbolic links
        # substantiate_date

        return result
      end

      # Substantiate symbolic links to files.
      def substantiate_date
        @outputs.flatten.compact.each do |output|
          if output.location.cached? and output.link?
            FileCache.get(output.location).turn(output.location)
          end
        end
      end
    end
  end
end

