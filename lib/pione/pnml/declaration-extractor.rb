module Pione
  module PNML
    class DeclarationExtractor
      def initialize(env, net, option={})
        @env = env
        @net = net
        @declarations = ExtractedDeclarations.new
      end

      def extract_params
        @net.transitions.each_with_object([]) do |transition, sentences|
          if Perspective.param_sentence?(transition)
            # evaluate the sentence for updating language environment
            Perspective.eval_param_sentence_transition(@env, transition)
            @declarations.add_param(transition.name)
          end
        end
      end

      def extract_variable_bindings
        @net.transitions.each do |transition|
          if Perspective.variable_binding?(transition)
            @declarations.add_variable_binding(transition.name)
          end
        end
      end

      def extract_features
        @net.transitions.each_with_object([]) do |transition, sentences|
          if Perspective.feature_sentence?(transition)
            
            @declarations.add_feature(transition.name)
          end
        end
      end
    end

    class ExtractedDeclarations
      attr_reader :params
      attr_reader :variable_bindings
      attr_reader :features

      def initialize
        @params = []
        @variable_bindings = []
        @features = []
      end

      def add_param(param)
        @params << Perspective.normalize_declaration(param)
      end

      def add_variable_binding(variable_binding)
        @variable_bindings <<
          Perspective.normalize_declaration(variable_binding)
      end

      def add_feature(feature)
        @features <<
          Perspective.normalize_declaration(feature)
      end
    end
  end
end
