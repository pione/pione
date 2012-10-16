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
require 'ostruct'

require 'pione/version'
require 'pione/util/terminal'
require 'pione/util/config'
require 'pione/util/message'
require 'pione/util/log'
require 'pione/common'
require 'pione/object'
require 'pione/identifier'
require 'pione/patch/array-patch'
require 'pione/patch/rinda-patch'
require 'pione/model'
require 'pione/tuple-space-server-interface'
require 'pione/tuple-space-server'
require 'pione/tuple-space-receiver'
require 'pione/tuple'
require 'pione/data-finder'
require 'pione/document'
require 'pione/update-criteria'
require 'pione/uri'
require 'pione/resource'
require 'pione/file-cache'
require 'pione/rule-handler/basic-handler'
require 'pione/rule-handler/flow-handler'
require 'pione/rule-handler/action-handler'
require 'pione/rule-handler/root-handler'
require 'pione/rule-handler/system-handler'
require 'pione/agent/basic-agent'
require 'pione/agent/exception'
require 'pione/agent/tuple-space-client'
require 'pione/agent/command-listener'
require 'pione/agent/task-worker'
require 'pione/agent/input-generator'
require 'pione/agent/rule-provider'
require 'pione/agent/logger'
require 'pione/agent/broker'
require 'pione/agent/broker-task-worker-life-checker'
require 'pione/agent/process-manager'
require 'pione/front/basic-front'
require 'pione/front/task-worker-owner'
require 'pione/front/broker-front'
require 'pione/front/task-worker-front'
require 'pione/front/stand-alone-front'
require 'pione/front/tuple-space-provider-front'

Thread.abort_on_exception = true

module Pione
  include Pione::Util
  include Pione::Util::Message
  include Pione::Model

  module_function :debug_mode=
  module_function :debug_mode?

  CONFIG = Config.instance
end

include Pione
