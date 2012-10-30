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
require 'dropbox_sdk'

#
# load pione
#

# version
require 'pione/version'

# util
require 'pione/util/misc'
require 'pione/util/terminal'
require 'pione/util/message'
require 'pione/util/log'
require 'pione/util/waiter-table'

# patch
require 'pione/patch/array-patch'
require 'pione/patch/drb-patch'
require 'pione/patch/rinda-patch'
require 'pione/patch/uri-patch'

# system
require 'pione/system/object'
require 'pione/system/common'
require 'pione/system/config'
require 'pione/system/global'
require 'pione/system/init'
require 'pione/system/identifier'
require 'pione/system/document'
require 'pione/system/file-cache'

Pione.module_exec {const_set(:PioneObject, Pione::System::PioneObject)}

# uri
require 'pione/uri/local.rb'
require 'pione/uri/dropbox.rb'

# relay
require 'pione/relay/relay-socket'
require 'pione/relay/relay-client-db'
require 'pione/relay/relay-account-db'

# model
require 'pione/model/model'
require 'pione/model/undefined-value'
require 'pione/model/list'
require 'pione/model/boolean'
require 'pione/model/integer'
require 'pione/model/float'
require 'pione/model/string'
require 'pione/model/feature-expr'
require 'pione/model/variable'
require 'pione/model/variable-table'
require 'pione/model/data-expr'
require 'pione/model/parameters'
require 'pione/model/package'
require 'pione/model/rule-expr'
require 'pione/model/binary-operator'
require 'pione/model/message'
require 'pione/model/call-rule'
require 'pione/model/assignment'
require 'pione/model/block'
require 'pione/model/rule'
require 'pione/model/rule-io'

# tuple-space
require 'pione/tuple-space/tuple'
require 'pione/tuple-space/tuple-space-server-interface'
require 'pione/tuple-space/presence-notifier'
require 'pione/tuple-space/tuple-space-server'
require 'pione/tuple-space/tuple-space-receiver'
require 'pione/tuple-space/tuple-space-provider'
require 'pione/tuple-space/data-finder'
require 'pione/tuple-space/update-criteria'

# parser
require 'pione/parser/syntax-error'
require 'pione/parser/common-parser'
require 'pione/parser/literal-parser'
require 'pione/parser/feature-expr-parser'
require 'pione/parser/expr-parser'
require 'pione/parser/flow-element-parser'
require 'pione/parser/block-parser'
require 'pione/parser/rule-definition-parser'
require 'pione/parser/document-parser'

# transformer
require 'pione/transformer/transformer-module'
require 'pione/transformer/literal-transformer'
require 'pione/transformer/feature-expr-transformer'
require 'pione/transformer/expr-transformer'
require 'pione/transformer/flow-element-transformer'
require 'pione/transformer/block-transformer'
require 'pione/transformer/rule-definition-transformer'
require 'pione/transformer/document-transformer'

# resource
require 'pione/resource/basic-resource'
require 'pione/resource/local'
require 'pione/resource/ftp'

# rule-handler
require 'pione/rule-handler/basic-handler'
require 'pione/rule-handler/flow-handler'
require 'pione/rule-handler/action-handler'
require 'pione/rule-handler/root-handler'
require 'pione/rule-handler/system-handler'

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

# front
require 'pione/front/basic-front'
require 'pione/front/task-worker-owner'
require 'pione/front/client-front'
require 'pione/front/broker-front'
require 'pione/front/task-worker-front'
require 'pione/front/tuple-space-provider-front'
require 'pione/front/tuple-space-receiver-front'
require 'pione/front/relay-front'

# command
require 'pione/command/basic-command'
require 'pione/command/front-owner'
require 'pione/command/daemon-process'
require 'pione/command/child-process'
require 'pione/command/pione-client'
require 'pione/command/pione-task-worker'
require 'pione/command/pione-broker'
require 'pione/command/pione-tuple-space-provider'
require 'pione/command/pione-tuple-space-receiver'
require 'pione/command/pione-tuple-space-viewer'
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
  include Parser
  include Transformer

  module_function :debug_mode=
  module_function :debug_mode?
end

include Pione
Thread.abort_on_exception = true
Pione::System::Init.new.init
