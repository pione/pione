module Pione
  module Command
    # PioneRelayAccountDB is a command that adds, deletes, shows your accounts
    # of relay servers.
    class PioneRelayAccountDB < BasicCommand
      define_info do
        set_name "pione-relay-account-db"
        set_banner "Add, delete, or show your accounts of relay servers."
      end

      define_option do
        option("-a", "--add", "add an account") do |data|
          data[:action] = :add
        end

        option("-d", "--delete", "delete an account") do |data|
          data[:action] = :delete
        end

        option("-l", "--list", "list accounts") do |data|
         data[:action] = :list
        end

        option("-r realm", "--realm realm", "realm name") do |data, realm|
          data[:realm] = realm
        end

        option("-u name", "--user name", "user name") do |data, name|
          data[:name] = name
        end

        option("-p password", "--password password", "password") do |data, password|
          data[:password] = password
        end

        option("-f path", "--file path", "account db path") do |data, path|
          Global.relay_account_db_path = path
        end

        validate do |data|
          abort("error: -a, -d, or -l") unless data[:action]
        end
      end

      def initialize
        @realm = nil
        @name = nil
        @password = nil
      end

      prepare do
        # set account db
        Global.relay_account_db = RelayAccountDB.new(Global.relay_account_db_path)

        # set realm
        if [:add, :delete].include?(option[:action])
          @realm = option[:realm] || HighLine.new.ask("Realm: ") unless @realm
        end

        # set name and password
        if option[:action] == :add
          @name = option[:name] || HighLine.new.ask("Name: ")
          unless @password = option[:password]
            @password = HighLine.new.ask("Password: "){|q| q.echo = "*"}
            password = HighLine.new.ask("Re-enter password: "){|q| q.echo = "*"}
            abort("error: password mismatch") unless @password == password
          end
        end
      end

      start do
        db = Global.relay_account_db
        case option[:action]
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
      end
    end
  end
end
