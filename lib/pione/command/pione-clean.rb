module Pione
  module Command
    # PioneClean is a command for clearing temporary files created by PIONE
    # system.
    class PioneClean < BasicCommand
      #
      # basic informations
      #

      command_name "pione-clean"
      command_banner "Clean working directories and file cache directories."

      #
      # options
      #

      use_option :debug

      #
      # command lifecycle: execution phase
      #

      execute :remove_working_directory
      execute :remove_cache_directory

      def execute_remove_working_directory
        FileUtils.remove_entry_secure(Global.working_directory_root)
      end

      def execute_remove_cache_directory
        FileUtils.remove_entry_secure(Global.file_cache_directory_root)
      end
    end
  end
end
