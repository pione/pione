require 'bundler/setup'
require 'set'
require 'socket'
require 'digest'
require 'socket'
require 'drb/drb'
require 'rinda/rinda'
require 'rinda/tuplespace'
require 'tempfile'
require 'yaml'
require 'singleton'
require 'timeout'
require 'thread'
require 'monitor'
require 'uri'
require 'pathname'
require 'uuidtools'
require 'json'
require 'parslet'

require 'pione/version'
require 'pione/util/terminal'
require 'pione/util/config'
require 'pione/util/message'
require 'pione/common'
require 'pione/object'
require 'pione/identifier'
require 'pione/rinda-patch'
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
  include Pione::Util::Message
  include Pione::Model

  def self.debug_mode=(arg)
    Pione::Util::Message.debug_mode = arg
  end

  CONFIG = Config.instance
end
