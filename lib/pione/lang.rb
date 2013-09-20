module Pione
  # Lang is a name space about PIONE language.
  module Lang; end
end

# meta system for PIONE language
require 'pione/lang/lang-exception'
require 'pione/lang/environment'
require 'pione/lang/definition'
require 'pione/lang/declaration'
require 'pione/lang/conditional-branch'
require 'pione/lang/context'

# semantics
require 'pione/lang/basic-model'      # model
require 'pione/lang/expr'             # expression
require 'pione/lang/piece'            # sequence piece
require 'pione/lang/pione-method'     # method system
require 'pione/lang/type'             # type
require 'pione/lang/sequence'         # sequence model
require 'pione/lang/ordinal-sequence' # sequence with integer key
require 'pione/lang/keyed-sequence'   # sequence with arbitrary expression key
require 'pione/lang/message'          # message
require 'pione/lang/variable'         # variable

# expression
require 'pione/lang/boolean'      # boolean
require 'pione/lang/integer'      # integer
require 'pione/lang/float'        # float
require 'pione/lang/string'       # string
require 'pione/lang/feature-expr' # feature
require 'pione/lang/data-expr'    # data expression
require 'pione/lang/parameters'   # parameter set
require 'pione/lang/package-expr' # package expression
require 'pione/lang/ticket-expr'  # ticket expression
require 'pione/lang/rule-expr'    # rule expression

