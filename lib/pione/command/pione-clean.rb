module Pione
  module Command
    class PioneClean
      def start
        FileUtils.remove_entry_secure(Global.working_directory_root)
        FileUtils.remove_entry_secure(Global.cache
      end
    end
  end
end
