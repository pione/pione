module Pione
  module Command
    # `PionePackageUpdate` is a subcommand that updates PIONE package.
    class PionePackageUpdate < BasicCommand
      #
      # basic informations
      #

      command_name "pione package update"
      command_banner "update the package to package database"

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

      # Update update info files.
      def execute_update
        Package::PackageHandler.write_info_files(Location[@target], force: option[:force])
      rescue Package::InvalidScenario => e
        abort(e.message)
      end
    end
  end
end
