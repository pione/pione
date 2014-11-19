module Pione
  module Command
    class CommandException < StandardError; end

    # SpawnError is raised when the command failed to run.
    class SpawnError < CommandException
      # Create a spawn error caused that child process is dead
      #
      # @param caller [String]
      #   caller name
      # @param callee [String]
      #   callee name
      # @param argv [Array<String>]
      #   arguments of process call
      # @return [SpawnError]
      #   a spawn error
      def self.child_process_is_dead(caller, callee, argv)
        new(caller, callee, argv, "child process is dead")
      end

      def initialize(caller, callee, argv, cause)
        @caller = caller
        @callee = callee
        @argv = argv
        @cause = cause
      end

      def message
        args = {caller: @caller, callee: @callee, argv: @argv, cause: @cause}
        '"%{caller}" has failed to spawn "%{callee}" %{argv}: %{cause}' % args
      end
    end

    # SpawnerRetry is raised when we need to try spawn check.
    class SpawnerRetry < CommandException; end

    # HideableOptionError is same as OptionError, but it is better for users
    # that this error is ignored in some cases.
    class HideableOptionError < Rootage::OptionError; end

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

