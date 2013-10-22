module Pione
  # Lang is a name space about PIONE language.
  module Lang; end
end

# PIONE language core
require 'pione/lang/lang-exception'     # exceptions
require 'pione/lang/environment'        # interpretation environment
require 'pione/lang/definition'         # definitions
require 'pione/lang/declaration'        # declarations
require 'pione/lang/conditional-branch' # conditional branch
require 'pione/lang/context'            # context

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

# language parser
require 'pione/lang/common-parser'             # common parser
require 'pione/lang/literal-parser'            # literal parser
require 'pione/lang/expr-parser'               # expression parser
require 'pione/lang/context-parser'            # context parser
require 'pione/lang/conditional-branch-parser' # conditional branch parser
require 'pione/lang/declaration-parser'        # declaration parser
require 'pione/lang/document-parser'           # document parser

# inner model transformer
require 'pione/lang/literal-transformer'            # literal transformer
require 'pione/lang/expr-transformer'               # expression transformer
require 'pione/lang/context-transformer'            # context transformer
require 'pione/lang/declaration-transformer'        # declaration transformer
require 'pione/lang/conditional-branch-transformer' # conditional branch transformer
require 'pione/lang/document-transformer'           # document transformer
