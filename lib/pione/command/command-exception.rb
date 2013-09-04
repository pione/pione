module Pione
  module Command
    class CommandException < StandardError; end

    # SpawnError is raised when the command failed to run.
    class SpawnError < CommandException; end
  end
end

