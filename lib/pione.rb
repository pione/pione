#
# load libraries
#
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

#
# load pione
#
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
require 'pione/resource/basic-resource'
Pione::Resource.autoload :Local, 'pione/resource/local'
Pione::Resource.autoload :FTP, 'pione/resource/ftp'
require 'pione/file-cache'
require 'pione/rule-handler/basic-handler'
require 'pione/rule-handler/flow-handler'
require 'pione/rule-handler/action-handler'
require 'pione/rule-handler/root-handler'
require 'pione/rule-handler/system-handler'
require 'pione/agent/basic-agent'
Pione::Agent.autoload :TupleSpaceClient, 'pione/agent/tuple-space-client'
Pione::Agent.autoload :CommandListener, 'pione/agent/command-listener'
Pione::Agent.autoload :TaskWorker, 'pione/agent/task-worker'
Pione::Agent.autoload :InputGenerator, 'pione/agent/input-generator'
Pione::Agent.autoload :RuleProvider, 'pione/agent/rule-provider'
Pione::Agent.autoload :Logger, 'pione/agent/logger'
Pione::Agent.autoload :Broker, 'pione/agent/broker'
Pione::Agent.autoload :BrokerTaskWrokerLifeChecker, 'pione/agent/broker-task-worker-life-checker'
Pione::Agent.autoload :ProcessManager, 'pione/agent/process-manager'
require 'pione/front/basic-front'
Pione::Front.autoload :TaskWorkerOwner, 'pione/front/task-worker-owner'
Pione::Front.autoload :BrokerFront, 'pione/front/broker-front'
Pione::Front.autoload :TaskWorkerFront, 'pione/front/task-worker-front'
Pione::Front.autoload :StandAloneFront, 'pione/front/stand-alone-front'
Pione::Front.autoload :TupleSpaceProviderFront, 'pione/front/tuple-space-provider-front'

#
# other settings
#
module Pione
  include Pione::Util
  include Pione::Util::Message
  include Pione::Model

  module_function :debug_mode=
  module_function :debug_mode?

  CONFIG = Config.instance
end

include Pione
Thread.abort_on_exception = true
