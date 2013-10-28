module Pione
  module System
    class Init
      def init
        # turn on "abort on exception" mode
        Thread.abort_on_exception = true

        # load configration file for global system
        Global::Config.load(Global.config_path)

        # make temporary directories
        unless Global.temporary_directory.exist?
          Global.temporary_directory.mkdir(0777)
        end

        # setup default temporary path generator
        Temppath.update_basedir(Global.my_temporary_directory + "others_%s" % Util::UUID.generate)

        # make file cache directory
        unless Global.file_cache_directory.exist?
          Global.file_cache_directory.mkdir(0777)
        end

        # make my file cache directory
        unless Global.file_cache_directory.exist?
          Global.file_cache_directory.mkdir(0777)
        end
      end
    end
  end
end
