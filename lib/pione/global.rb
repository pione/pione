module Pione
  # Global is a table of global variables in PIONE system. It defines variable
  # names, initial values, and configuration conditions. You can set and get
  # value by calling item named method.
  module Global; end
end

require 'pione/global/global-exception'
require 'pione/global/item'
require 'pione/global/config'
require 'pione/global/system-variable'
require 'pione/global/path-variable'
require 'pione/global/network-variable'
require 'pione/global/log-variable'
require 'pione/global/relay-variable'
require 'pione/global/client-variable'
require 'pione/global/task-worker-variable'
require 'pione/global/broker-variable'
require 'pione/global/input-generator-variable'
require 'pione/global/tuple-space-notifier-variable'
require 'pione/global/package-variable'
