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
        use Option::CommonOption.debug
        use Option::CommonOption.color

        define(:add) do |item|
          item.short = "-a"
          item.long = "--add"
          item.desc = "add an account"
          item.action = lambda {|option| option[:action] = :add}
        end

        define(:delete) do |item|
          item.short = "-d"
          item.long = "--delete"
          item.desc = "delete an account"
          item.action = lambda {|option| option[:action] = :delete}
        end

        define(:list) do |item|
          item.short = "-l"
          item.long = "--list"
          item.desc = "list accounts"
          item.action = lambda {|option| option[:action] = :list}
        end

        define(:realm) do |item|
          item.short = "-r"
          item.long = "--realm=REALM"
          item.desc = "realm name"
          item.value = lambda {|name| name}
        end

        define(:name) do |item|
          item.short = "-u"
          item.long = "--user=NAME"
          item.desc = "user name"
          item.value = lambda {|name| name}
        end

        define(:password) do |item|
          item.short = "-p"
          item.long = "--password=PASSWORD"
          item.desc = "password"
          item.value = lambda {|password| password}
        end

        define(:file) do |item|
          item.short = "-f"
          item.long = "--file=PATH"
          item.desc = "account db path"
          item.action = lambda {|path| Global.relay_account_db_path = path}
        end

        validate do |option|
          abort("error: -a, -d, or -l") unless option[:action]
        end
      end

      def initialize(*options)
        super(*options)
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
