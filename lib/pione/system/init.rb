module Pione
  module System
    class Init
      def init
        # init globals
        Global.init

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

        # relay client database
        Global.relay_client_db = Relay::RelayClientDB.new(Global.relay_client_db_path)

        # relay account database
        Global.relay_account_db = Relay::RelayAccountDB.new(Global.relay_account_db_path)
      end
    end
  end
end
