module Pione
  module Command
    class PioneRelayAccountDB < BasicCommand
      set_program_name("pione-relay-account-db")

      define_option("-a", "--add", "add an account") do
        @action = :add
      end

      define_option("-d", "--delete", "delete an account") do
        @action = :delete
      end

      define_option("-l", "--list", "list accounts") do
        @action = :list
      end

      define_option("-r realm", "--realm realm", "realm name") do |realm|
        @realm = realm
      end

      define_option("-u name", "--user name", "user name") do |name|
        @name = name
      end

      define_option("-p password", "--password password", "password") do |password|
        @password = password
      end

      define_option("-f path", "--file path", "account db path") do |path|
        Global.relay_account_db_path = path
      end

      def initialize
        @action = nil
        @name = nil
        @password = nil
      end

      def validate_options
        abort("error: -a, -d, or -l") unless @action
      end

      def prepare
        # set account db
        Global.relay_account_db = RelayAccountDB.new(Global.relay_account_db_path)

        # set realm
        if [:add, :delete].include?(@action)
          @realm = HighLine.new.ask("Realm: ") unless @realm
        end

        # set name and password
        if @action == :add
          @name = HighLine.new.ask("Name: ") unless @name
          unless @password
            @password = HighLine.new.ask("Password: "){|q| q.echo = "*"}
            password = HighLine.new.ask("Re-enter password: "){|q| q.echo = "*"}
            abort("error: password mismatch") unless @password == password
          end
        end
      end

      def start
        db = Global.relay_account_db
        case @action
        when :add
          db.add(@realm, @name, @password)
          db.save
        when :delete
          db.delete(@realm)
          db.save
        when :list
          puts "%s accounts in %s" % [db.realms.size, Global.relay_account_db_path]
          db.realms.each {|realm| puts "%s:%s" % [realm, db[realm].name]}
        end
        terminate
      end
    end
  end
end
