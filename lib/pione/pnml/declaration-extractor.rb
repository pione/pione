module Pione
  module PNML
    # DeclarationExtractor extracts declarations from net.
    class DeclarationExtractor
      def initialize(env, net, option={})
        @env = env
        @net = net
        @declarations = ExtractedDeclarations.new
      end

      def extract
        extract_params
        extract_variable_bindings
        extract_features

        return @declarations
      end

      private

      # Extract net parameters.
      def extract_params
        @net.transitions.each_with_object([]) do |transition, sentences|
          if Perspective.param_transition?(@env, transition)
            # evaluate the sentence for updating language environment
            Perspective.eval_param_sentence(@env, transition)
            @declarations.add_param(transition.name)
          end
        end
      end

      # Extract net variable bindings.
      def extract_variable_bindings
        @net.transitions.each do |transition|
          if Perspective.variable_binding_transition?(@env, transition)
            @declarations.add_variable_binding(transition.name)
          end
        end
      end

      # Extract net features.
      def extract_features
        @net.transitions.each_with_object([]) do |transition, sentences|
          if Perspective.feature_transition?(@env, transition)
            @declarations.add_feature(transition.name)
          end
        end
      end
    end

    # ExtractedDeclarations is a store of declarations.
    class ExtractedDeclarations
      attr_reader :params
      attr_reader :variable_bindings
      attr_reader :features

      def initialize
        @params = []
        @variable_bindings = []
        @features = []
      end

      # Add the parameter.
      #
      # @param param [String]
      #   a string of parameter
      def add_param(param)
        @params << Perspective.normalize_declaration(param)
      end

      # Add the variable binding.
      #
      # @param variable_binding [String]
      #   a string of variable binding
      def add_variable_binding(variable_binding)
        @variable_bindings <<
          Perspective.normalize_declaration(variable_binding)
      end

      # Add the feature.
      #
      # @param variable_binding [String]
      #   a string of feature
      def add_feature(feature)
        @features <<
          Perspective.normalize_declaration(feature)
      end
    end
  end
end
