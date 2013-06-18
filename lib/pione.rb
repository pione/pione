#
# load libraries
#
require 'bundler/setup'
require 'set'
require 'socket'
require 'digest'
require 'forwardablex'
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
require 'time'
require 'etc'
require 'json'
require 'rexml/document'
require 'logger'
require 'ostruct'
require 'net/ftp'
require 'net/http'

require 'uuidtools'
require 'parslet'
require 'highline'
require 'dropbox_sdk'
require 'hamster'
require 'naming'
require 'temppath'
require 'xes'
require 'sys/uname'
require 'simple-identity'
require 'rainbow'
require 'em-ftpd'
require 'pione/patch/em-ftpd-patch'
require 'sys/cpu'
require 'structx'
require 'syslog-logger'

#
# load pione
#

require 'pione/version'
require 'pione/util'

# patch
require 'pione/patch/array-patch'
require 'pione/patch/drb-patch'
require 'pione/patch/rinda-patch'
require 'pione/patch/uri-patch'
require 'pione/patch/monitor-patch'

require 'pione/uri-scheme'
require 'pione/location'
require 'pione/log'
require 'pione/system'

Pione.module_exec {const_set(:PioneObject, Pione::System::PioneObject)}
Pione.module_exec {const_set(:Global, Pione::System::Global)}

# relay
require 'pione/relay/transmitter-socket'
require 'pione/relay/trampoline'
require 'pione/relay/receiver-socket'
require 'pione/relay/relay-socket'
require 'pione/relay/relay-client-db'
require 'pione/relay/relay-account-db'

# tuple-space
require 'pione/tuple-space/tuple-space-server-interface'
require 'pione/tuple-space/presence-notifier'
require 'pione/tuple-space/tuple-space-server'
require 'pione/tuple-space/tuple-space-receiver'
require 'pione/tuple-space/tuple-space-provider'
require 'pione/tuple-space/data-finder'

# rule-handler
require 'pione/rule-handler.rb'

require 'pione/model'
require 'pione/component'

# tuple
require 'pione/tuple'

# parser
require 'pione/parser/parslet-extension'
require 'pione/parser/common-parser'
require 'pione/parser/literal-parser'
require 'pione/parser/feature-expr-parser'
require 'pione/parser/expr-parser'
require 'pione/parser/flow-element-parser'
require 'pione/parser/block-parser'
require 'pione/parser/rule-definition-parser'
require 'pione/parser/document-parser'

# transformer
require 'pione/transformer'

# agent
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
require 'pione/agent/messenger'

# front
require 'pione/front/basic-front'
require 'pione/front/task-worker-owner'
require 'pione/front/tuple-space-provider-owner'
require 'pione/front/client-front'
require 'pione/front/broker-front'
require 'pione/front/task-worker-front'
require 'pione/front/tuple-space-provider-front'
require 'pione/front/tuple-space-receiver-front'
require 'pione/front/relay-front'

# command
require 'pione/command'

#
# other settings
#
module Pione
  include System
  include Relay
  include Util
  include Log::MessageLog
  include Model
  include TupleSpace
  include Parser
  include Transformer

  extend Util::Evaluatable

  module_function :debug_mode
  module_function :debug_mode=
  module_function :debug_mode?
end

include Pione
Thread.abort_on_exception = true
Pione::System::Init.new.init
