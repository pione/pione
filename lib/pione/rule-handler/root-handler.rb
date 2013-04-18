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
        copy_data_into_domain(@inputs.flatten, @domain)
        # execute the rule
        result = super
        # export outputs to output domain
        copy_data_into_domain(@outputs.flatten, '/output')
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

