module Pione
  # `PNML` is a namespace for the compiler from PNML to PIONE.
  module PNML; end
end

require 'pione/pnml/pnml-exception'

#
# language model
#

require 'pione/pnml/parser'
require 'pione/pnml/pnml-model'  # source models
require 'pione/pnml/pione-model' # target models

#
# net rewriting rules
#

require 'pione/pnml/net-rewriter'
require 'pione/pnml/output-reduction'
require 'pione/pnml/input-reduction'
require 'pione/pnml/isolated-element-elimination'
require 'pione/pnml/input-merge-complement'
require 'pione/pnml/input-parallelization-complement'
require 'pione/pnml/output-decomposition-complement'
require 'pione/pnml/output-synchronization-complement'
require 'pione/pnml/io-expansion'
require 'pione/pnml/invalid-arc-elimination'
require 'pione/pnml/ticket-instantiation'

#
# utility
#

require 'pione/pnml/annotation-extractor'
require 'pione/pnml/reader'
require 'pione/pnml/compiler'

