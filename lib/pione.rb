#
# load libraries
#
require 'bundler/setup'
require 'set'
require 'socket'
require 'digest'
require 'forwardable'
require 'socket'
require 'drb/drb'
require 'drb/ssl'
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
require 'net/ftp'
require 'highline'

#
# load pione
#
require 'pione/version'
require 'pione/system/config'
require 'pione/system/global'
require 'pione/system/init'
require 'pione/common'
require 'pione/object'
require 'pione/util/terminal'
require 'pione/util/message'
require 'pione/util/log'
require 'pione/identifier'
require 'pione/patch/array-patch'
require 'pione/patch/rinda-patch'
require 'pione/relay/relay-socket'
require 'pione/relay/relay-client-db'
require 'pione/relay/relay-account-db'
require 'pione/model/model'
require 'pione/tuple-space/tuple'
require 'pione/tuple-space/tuple-space-server-interface'
require 'pione/tuple-space/presence-notifier'
require 'pione/tuple-space/tuple-space-server'
require 'pione/tuple-space/tuple-space-receiver'
require 'pione/tuple-space/tuple-space-provider'
require 'pione/tuple-space/data-finder'
require 'pione/document'
require 'pione/parser/parser'
require 'pione/transformer/transformer'
require 'pione/update-criteria'
require 'pione/uri'
require 'pione/resource/basic-resource'
require 'pione/resource/local'
require 'pione/resource/ftp'
require 'pione/file-cache'
require 'pione/rule-handler/basic-handler'
require 'pione/rule-handler/flow-handler'
require 'pione/rule-handler/action-handler'
require 'pione/rule-handler/root-handler'
require 'pione/rule-handler/system-handler'
require 'pione/agent/basic-agent'
require 'pione/agent/tuple-space-client'
require 'pione/agent/command-listener'
require 'pione/agent/task-worker'
require 'pione/agent/input-generator'
require 'pione/agent/rule-provider'
require 'pione/agent/logger'
require 'pione/agent/broker'
require 'pione/agent/process-manager'
require 'pione/agent/trivial-routine-worker'
require 'pione/agent/tuple-space-server-client-life-checker'
require 'pione/front/basic-front'
require 'pione/front/task-worker-owner'
require 'pione/front/client-front'
require 'pione/front/broker-front'
require 'pione/front/task-worker-front'
require 'pione/front/tuple-space-provider-front'
require 'pione/front/tuple-space-receiver-front'
require 'pione/front/relay-front'
require 'pione/command/basic-command'
require 'pione/command/front-owner'
require 'pione/command/daemon-process'
require 'pione/command/child-process'
require 'pione/command/pione-client'
require 'pione/command/pione-task-worker'
require 'pione/command/pione-broker'
require 'pione/command/pione-tuple-space-provider'
require 'pione/command/pione-tuple-space-receiver'
require 'pione/command/pione-relay'
require 'pione/command/pione-relay-client-db'
require 'pione/command/pione-relay-account-db'

#
# other settings
#
module Pione
  include System
  include Relay
  include Util
  include Util::Message
  include Model
  include TupleSpace

  module_function :debug_mode=
  module_function :debug_mode?
end

include Pione
Thread.abort_on_exception = true
Pione::System::Init.new.init
