Thread.abort_on_exception = true

#
# setup bundler
#

require 'bundler/setup' rescue nil

#
# initialize profiler
#

require 'pione/util/profiler'
if targets = ENV["PIONE_PROFILE"]
  Pione::Util::Profiler.init
  Pione::Util::Profiler.targets.concat(targets.split(":"))
end

#
# load libraries
#

# standard
require 'set'
require 'socket'
require 'digest'
require 'forwardablex'
require 'socket'
require 'ipaddr'
require 'drb/drb'
require 'drb/ssl'
require 'rinda/rinda'
require 'rinda/tuplespace'
require 'tempfile'
require 'yaml'
require 'singleton'
require 'timeout'
require 'thread'
require 'thwait'
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
require 'fiber'

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
require 'zip'
require 'zip/filesystem'
require 'retriable'
require 'childprocess'
require 'lettercase/core_ext'
require 'kramdown'
require 'os'
require 'sys/proctable'

# configuration for childprcess
ChildProcess.posix_spawn = true

require 'rootage'

#
# load pione
#

require 'pione/version'         # PIONE version information
require 'pione/util'            # various helper functions
require 'pione/patch'           # patches for libraries
require 'pione/notification'    # PIONE notification system
require 'pione/location'        # location system for data and package
require 'pione/log'             # log and format
require 'pione/global'          # global variable manager
require 'pione/system'          # PIONE system functions
require 'pione/relay'           # relay connection
require 'pione/package'         # package system
require 'pione/lang'            # PIONE languge
require 'pione/tuple-space'     # tuple space functions
require 'pione/rule-engine'     # rule processing behaviors
require 'pione/agent'           # agent system
require 'pione/model'           # command model
require 'pione/front'           # command front interface
require 'pione/command'         # command definitions
require 'pione/literate-action' # literate action
require 'pione/task-worker-broker' # task worker broker

#
# other settings
#

module Pione
  # expand name spaces
  include Relay
  include Log::MessageLog
  include TupleSpace

  extend Util::Evaluatable
end

# initialize PIONE system
Pione::System::Init.new.init

# now, we are enable to start processing!
