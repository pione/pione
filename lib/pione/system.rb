module Pione
  module System
  end
end

require 'pione/system/object'
require 'pione/system/common'
require 'pione/system/config'
require 'pione/system/init'
require 'pione/system/file-cache'
require 'pione/system/domain-info'

# export some classes to the name space of Pione
Pione.module_exec {const_set(:PioneObject, Pione::System::PioneObject)}

