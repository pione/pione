module Pione
  module Command
    # PioneRelayClientDB is a command that adds, deletes, or shows clients in
    # relay server.
    class PioneRelayClientDB < BasicCommand
      #
      # basic informations
      #

      command_name "pione-relay-client-db"
      command_banner "Add, delete, or show clients in this relay server."

      #
      # options
      #

      use_option :color
      use_option :debug

      define_option(:add) do |item|
        item.short = "-a"
        item.long = "--add"
        item.desc = "add a client"
        item.action = lambda {|_, option| option[:action] = :add}
      end

      define_option(:delete) do |item|
        item.short = "-d"
        item.long = "--delete"
        item.desc = "delete a client"
        item.action = lambda {|_, option| option[:action] = :delete}
      end

      define_option(:list) do |item|
        item.short = "-l"
        item.long = "--list"
        item.desc = "list clients"
        item.action = lambda {|_, option| option[:action] = :list}
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
        item.desc = "client db path"
        item.action = lambda {|_, option, path| Global.relay_client_db_path = path}
      end

      validate_option do |option|
        abort("error: -a, -d, or -l") unless option[:action]
      end

      #
      # command lifecycle: setup phase
      #

      setup :client_db
      setup [:add, :delete] => :name
      setup :add => :password

      # set client db
      def setup_client_db
        Global.relay_client_db = RelayClientDB.new(Global.relay_client_db_path)
      end

      # set name
      def setup_name
        option[:name] = HighLine.new.ask("Name: ") unless option[:name]
      end

      # set password
      def setup_password
        unless option[:password]
          option[:password] = HighLine.new.ask("Password: "){|q| q.echo = "*"}
          password = HighLine.new.ask("Re-enter password: "){|q| q.echo = "*"}
          abort("error: password mismatch") unless option[:password] == password
        end
      end

      #
      # command lifecycle: execution phase
      #

      execute :add => :add
      execute :delete => :delete
      execute :list => :list

      def execute_add
        Global.relay_client_db.add(option[:name], option[:password])
        Global.relay_client_db.save
      end

      def execute_delete
        Global.relay_client_db.delete(option[:name])
        Global.relay_client_db.save
      end

      def execute_list
        names = Global.relay_client_db.names
        puts "%s clients in %s" % [names.size, Global.relay_client_db_path]
        names.each {|user| puts user}
      end
    end
  end
end
