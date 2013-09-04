module Pione
  module RuleEngine
    # RootHandler is a special handler for RootRule.
    class RootHandler < FlowHandler
      def execute
        # import initial input tuples from input domain
        @inputs.flatten.each {|input| copy_data_into_domain(input, @domain_id)}
        # execute the rule
        outputs = super
        # export outputs to output domain
        outputs.flatten.each {|output| copy_data_into_domain(output, '/output')}
        # substantiate symbolic links
        # substantiate_date

        return outputs
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

