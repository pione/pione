require 'set'
require 'uuidtools'
require 'socket'
require 'digest'
require 'socket'
require 'drb/drb'
require 'rinda/rinda'
require 'rinda/tuplespace'
require 'json'
require 'tempfile'
require 'pione'
require 'yaml'
require 'singleton'
require 'timeout'
require 'thread'
require 'monitor'
require 'parslet'
require 'uri'

module Pione
  VERSION = 0

  def version
    "%s" % VERSION
  end
  module_function :version

  # Basic object class for PIONE system.
  class PioneObject
    # Returns this object's uuid.
    # @return [String] UUID string
    def uuid
      @__uuid__ ||= generate_uuid
    end

    # Finalizes this object.
    # @return [void]
    def finalize
      # do nothing
    end
  end
end

require 'pione/util/terminal'
require 'pione/util/config'
require 'pione/util/message'
require 'pione/rinda-patch'
require 'pione/common'
require 'pione/model'
require 'pione/tuple-space-server-interface'
require 'pione/tuple-space-server'
require 'pione/log'
require 'pione/tuple'
require 'pione/data-finder'
require 'pione/document'
require 'pione/update-criteria'
require 'pione/rule-handler'
require 'pione/uri'
require 'pione/resource'
require 'pione/file-cache'
require 'pione/agent'

module Pione
  include Pione::Util
  include Pione::Model

  CONFIG = Config.new
end
