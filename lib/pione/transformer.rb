require 'pione/transformer/transformer-module'
require 'pione/transformer/literal-transformer'
require 'pione/transformer/expr-transformer'
require 'pione/transformer/context-transformer'
require 'pione/transformer/declaration-transformer'
require 'pione/transformer/conditional-branch-transformer'
require 'pione/transformer/document-transformer'
require 'pione/transformer/interpolator-transformer'

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
