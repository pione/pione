module Pione
  # Model is a name space for all PIONE models.
  module Model
  end
end

# load all models
require 'pione/model/exception'
require 'pione/model/expr'
require 'pione/model/piece'
require 'pione/model/type'
require 'pione/model/pione-method'
require 'pione/model/basic-model'
require 'pione/model/sequence'
require 'pione/model/ordinal-sequence'
require 'pione/model/keyed-sequence'
require 'pione/model/boolean'
require 'pione/model/integer'
require 'pione/model/float'
require 'pione/model/string'
require 'pione/model/feature-expr'
require 'pione/model/variable'
require 'pione/model/data-expr'
require 'pione/model/parameters'
require 'pione/model/package-expr'
require 'pione/model/ticket-expr'
require 'pione/model/rule-expr'
require 'pione/model/message'

