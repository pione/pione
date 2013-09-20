module Pione
  module Command
    # PioneRelayAccountDB is a command that adds, deletes, shows your accounts
    # of relay servers.
    class PioneRelayAccountDB < BasicCommand
      #
      # basic informations
      #

      command_name "pione-relay-account-db"
      command_banner "Add, delete, or show your accounts of relay servers."

      #
      # options
      #

      use_option :color
      use_option :debug

      define_option(:add) do |item|
        item.short = "-a"
        item.long = "--add"
        item.desc = "add an account"
        item.action = lambda {|_, option| option[:action] = :add}
      end

      define_option(:delete) do |item|
        item.short = "-d"
        item.long = "--delete"
        item.desc = "delete an account"
        item.action = lambda {|_, option| option[:action] = :delete}
      end

      define_option(:list) do |item|
        item.short = "-l"
        item.long = "--list"
        item.desc = "list accounts"
        item.action = lambda {|_, option| option[:action] = :list}
      end

      define_option(:realm) do |item|
        item.short = "-r"
        item.long = "--realm=REALM"
        item.desc = "realm name"
        item.value = lambda {|name| name}
      end

      define_option(:name) do |item|
        item.short = "-u"
        item.long = "--user=NAME"
        item.desc = "user name"
        item.value = lambda {|name| name}
      end

      define_option(:password) do |item|
        item.short = "-p"
        item.long = "--password=PASSWORD"
        item.desc = "password"
        item.value = lambda {|password| password}
      end

      define_option(:file) do |item|
        item.short = "-f"
        item.long = "--file=PATH"
        item.desc = "account db path"
        item.action = lambda {|_, _, path| Global.relay_account_db_path = path}
      end

      validate_option do |option|
        abort("error: -a, -d, or -l") unless option[:action]
      end

      #
      # instance methods
      #

      def initialize(*options)
        super(*options)
        @realm = nil
        @name = nil
        @password = nil
      end

      #
      # command lifecycle: setup phase
      #

      setup :account_db
      setup [:add, :delete] => :realm
      setup :add => :name_and_password

      # Set account db.
      def setup_account_db
        Global.relay_account_db = RelayAccountDB.new(Global.relay_account_db_path)
      end

      # Get realm name from user input.
      def setup_realm
        @realm = option[:realm] || HighLine.new.ask("Realm: ") unless @realm
      end

      # Get user name and password from user input.
      def setup_name_and_password
        @name = option[:name] || HighLine.new.ask("Name: ")
        unless @password = option[:password]
          @password = HighLine.new.ask("Password: "){|q| q.echo = "*"}
          password = HighLine.new.ask("Re-enter password: "){|q| q.echo = "*"}
          abort("error: password mismatch") unless @password == password
        end
      end

      #
      # command lifecycle: execution phase
      #

      execute :add => :add
      execute :delete => :delete
      execute :list => :list

      # Add a user.
      def execute_add
        Global.relay_account_db.add(@realm, @name, @password)
        Global.relay_account_db.save
      end

      # Delete a user.
      def execute_delete
        Global.relay_account_db.delete(@realm)
        Global.relay_account_db.save
      end

      # Show all users.
      def execute_list
        puts "%s accounts in %s" % [db.realms.size, Global.relay_account_db_path]
        Global.relay_account_db.realms.each do |realm|
          puts "%s:%s" % [realm, Global.relay_account_db[realm].name]
        end
      end
    end
  end
end
