module Pione
  module Command
    # PioneClean is a command for clearing temporary files of PIONE system.
    class PioneClean < BasicCommand
      define_info do
        set_name "pione-clean"
        set_banner "Clean working directories and file cache directories."
      end

      define_option do
        use :debug
      end

      start do
        FileUtils.remove_entry_secure(Global.working_directory_root)
        FileUtils.remove_entry_secure(Global.file_cache_directory_root)
      end
    end
  end
end
