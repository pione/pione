module Pione
  module PNML
    # `NetRewriter` is a class for rewriting PNML's net by PIONE's rewriting
    # rules likes "input reduction", "output reduction", "IO expansion", and
    # etc.
    class NetRewriter
      # Create a new net rewriter. Rewriting rules are setuped by the block.
      #
      #     PNML::NetRewriter.new do |rules|
      #       rules << PNML::InputReduction
      #       rules << PNML::OutputReduction
      #       rules << PNML::IOExpansion
      #     end
      def initialize(&b)
        @rules = []
        if block_given?
          yield @rules
        end
      end

      # Rewrite the net by rewriting rules recursively.
      #
      # @param net [PNML::Net]
      #   a net that is a target of this transformation
      # @return [void]
      def rewrite(net)
        # find rewriting subjects
        rule, subjects = @rules.inject(nil) do |res, _rule|
          if res.nil? and _subjects = _rule.find_subjects(net)
            [_rule, _subjects]
          else
            res
          end
        end

        # rewrite the net with subjects and go next
        if subjects
          rule.rewrite(net, subjects)
          rewrite(net)
        end
      end
    end
  end
end
