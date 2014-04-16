module Pione
  # Command is a name space for PIONE command classes.
  module Command
    def self.load_all
      require 'pione/command/pione-action'
      require 'pione/command/pione-action-exec'
      require 'pione/command/pione-action-list'
      require 'pione/command/pione-action-print'
      require 'pione/command/pione-clean'
      require 'pione/command/pione-compile'
      require 'pione/command/pione-config'
      require 'pione/command/pione-config-get'
      require 'pione/command/pione-config-list'
      require 'pione/command/pione-config-set'
      require 'pione/command/pione-config-unset'
      require 'pione/command/pione-diagnosis'
      require 'pione/command/pione-diagnosis-notification'
      require 'pione/command/pione-lang'
      require 'pione/command/pione-lang-check-syntax'
      require 'pione/command/pione-log'
      require 'pione/command/pione-log-format'
      require 'pione/command/pione-log-list-id'
      require 'pione/command/pione-package'
      require 'pione/command/pione-package-add'
      require 'pione/command/pione-package-build'
      require 'pione/command/pione-package-show'
      require 'pione/command/pione-package-update'
    end
  end
end

require 'pione/command/command-exception'
require 'pione/command/common'
require 'pione/command/spawner'
require 'pione/command/option'
require 'pione/command/action'
require 'pione/command/basic-command'
require 'pione/command/pione-command'
require 'pione/command/pione-client'
require 'pione/command/pione-task-worker'
require 'pione/command/pione-task-worker-broker'
require 'pione/command/pione-tuple-space-provider'
require 'pione/command/pione-notification-listener'
require 'pione/command/pione-tuple-space-viewer'

