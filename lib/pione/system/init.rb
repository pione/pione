module Pione
  module System
    class Init
      def init
        # turn on "abort on exception" mode
        Thread.abort_on_exception = true

        # load configration file
        System::Config.load(Global.config_path)

        # make temporary directories
        unless Global.temporary_directory_root.exist?
          Global.temporary_directory_root.mkdir(0777)
        end
        unless Global.temporary_directory.exist?
          Global.temporary_directory.mkdir(0700)
        end
        unless Global.working_directory_root.exist?
          Global.working_directory_root.mkdir(0777)
        end
        unless Global.working_directory.exist?
          Global.working_directory.mkdir(0700)
        end
        unless Global.file_cache_directory_root.exist?
          Global.file_cache_directory_root.mkdir(0777)
        end
        unless Global.file_cache_directory.exist?
          Global.file_cache_directory.mkdir(0700)
        end
      end
    end
  end
end
