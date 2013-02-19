module Pione
  module System
    class Init
      def init
        # init globals
        Global.init

        # load configration file
        System::Config.load(Global.config_path)

        # relay client database
        Global.relay_client_db = Relay::RelayClientDB.new(Global.relay_client_db_path)

        # relay account database
        Global.relay_account_db = Relay::RelayAccountDB.new(Global.relay_account_db_path)
      end
    end
  end
end
