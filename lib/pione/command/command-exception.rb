module Pione
  module Command
    class CommandException < StandardError; end

    # SpawnError is raised when the command failed to run.
    class SpawnError < CommandException; end

    # SpawnerRetry is raised when we need to try spawn check.
    class SpawnerRetry < CommandException; end

    # OptionError is raised when the command option is invalid.
    class OptionError < CommandException
      def initialize(msg)
        @msg = msg
      end

      def message
        "option error: %s" % @msg
      end
    end

    # HideableOptionError is same as OptionError, but it is better for users
    # that this error is ignored in some cases.
    class HideableOptionError < OptionError; end

    class ActionNotFound < CommandException
      def initialize(mod, name)
        @mod = mod
        @name = name
      end

      def message
        "Command action \"%s\" not found in %s." % [@name, @mod]
      end
    end
  end
end

