#
# load libraries
#

# bundler
require 'bundler/setup' rescue nil

# standard
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

# gems
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
require 'pione/patch/em-ftpd-patch' # patch
require 'sys/cpu'
require 'structx'
require 'syslog-logger'
require 'zipruby'
require 'retriable'
require 'childprocess'

ChildProcess.posix_spawn = true

#
# load pione
#

require 'pione/version'
require 'pione/util'
require 'pione/patch'
require 'pione/uri-scheme'
require 'pione/location'
require 'pione/log'
require 'pione/system'

Pione.module_exec {const_set(:PioneObject, Pione::System::PioneObject)}
Pione.module_exec {const_set(:Global, Pione::System::Global)}

require 'pione/relay'
require 'pione/tuple-space'
require 'pione/rule-handler.rb'
require 'pione/model'
require 'pione/component'
require 'pione/tuple'
require 'pione/parser'
require 'pione/transformer'
require 'pione/agent'
require 'pione/front'
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
