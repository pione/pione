module Pione
  # Front is a namespace for process fronts.
  module Front; end
end

require 'pione/front/front-exception'
require 'pione/front/basic-front'
require 'pione/front/notification-recipient-interface'
require 'pione/front/client-front'
require 'pione/front/task-worker-front'
require 'pione/front/task-worker-broker-front'
require 'pione/front/tuple-space-provider-front'
require 'pione/front/notification-listener-front'
require 'pione/front/relay-front'
require 'pione/front/diagnosis-notification-front'
