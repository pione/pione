module Pione
  module System
  end
end

require 'pione/system/system-exception'
require 'pione/system/object'
require 'pione/system/common'
require 'pione/system/init'
require 'pione/system/file-cache'
require 'pione/system/domain-dump'
require 'pione/system/status'
require 'pione/system/normalizer'

# export some classes to the name space of Pione
Pione.module_exec {const_set(:PioneObject, Pione::System::PioneObject)}

