module Pione
  # `PNML` is a namespace for the compiler from PNML to PIONE.
  module PNML; end
end

#
# language model
#

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

#
# translating rules
#

# require 'pione/pnml/translational-rule' # base
# require 'pione/pnml/input-parallelization'
# require 'pione/pnml/output-parallelization'
# require 'pione/pnml/input-merge'
# require 'pione/pnml/output-merge'

#
# utility
#

require 'pione/pnml/reader'

