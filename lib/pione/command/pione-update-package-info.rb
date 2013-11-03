module Pione
  module Command
    # PioneUpdatePackageInfo is a command definition of "pione
    # update-package-info".
    class PioneUpdatePackageInfo < BasicCommand
      #
      # basic informations
      #

      command_name "pione update-package-info"
      command_banner "update package info files"
      PioneCommand.add_subcommand("update-package-info", self)

      #
      # options
      #

      use_option :color
      use_option :debug

      define_option(:force) do |item|
        item.long = "--force"
        item.desc = "update pacakge info files"
        item.value = lambda {|b| b}
      end

      #
      # command lifecycle: setup phase
      #

      setup :target

      # Check archiver target location.
      def setup_target
        abort("There are no PIONE documents or packages.")  if @argv.first.nil?
        @target = @argv.first
      end

      #
      # command lifecycle: execution phase
      #

      execute :update

      # Update pacakge info files.
      def execute_update
        Package::PackageHandler.write_info_files(Location[@target], force: option[:force])
      rescue Package::InvalidScenario => e
        abort(e.message)
      end
    end
  end
end
