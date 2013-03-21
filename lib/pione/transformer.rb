require 'pione/transformer/transformer-module'
require 'pione/transformer/literal-transformer'
require 'pione/transformer/feature-expr-transformer'
require 'pione/transformer/expr-transformer'
require 'pione/transformer/flow-element-transformer'
require 'pione/transformer/block-transformer'
require 'pione/transformer/rule-definition-transformer'
require 'pione/transformer/document-transformer'

module Pione
  # Transformer is a name space for PIONE document transformers and provides
  # utilities.
  module Transformer
    # Transform by applying DocumentTransformer.
    #
    # @param syntax_tree [Hash]
    #   target syntax tree
    # @return [Object]
    #   transformed object
    def self.document(syntax_tree)
      DocumentTransformer.new.apply(syntax_tree)
    end
  end
end
