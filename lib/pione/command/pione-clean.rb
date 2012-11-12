module Pione
  module Command
    class PioneClean < BasicCommand
      set_program_name("pione-clean")

      set_program_message <<TXT
Cleans working directories and file cache directories.
TXT

      def start
        FileUtils.remove_entry_secure(Global.working_directory_root)
        FileUtils.remove_entry_secure(Global.file_cache_directory_root)
      end
    end
  end
end
