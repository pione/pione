module Pione
  module Command
    # PioneRelayClientDB is a command that adds, deletes, or shows clients in
    # relay server.
    class PioneRelayClientDB < BasicCommand
      define_info do
        set_name "pione-relay-client-db"
        set_banner "Add, delete, or show clients in this relay server."
      end

      define_option do
        use Option::CommonOption.debug
        use Option::CommonOption.color

        define(:add) do |item|
          item.short = "-a"
          item.long = "--add"
          item.desc = "add a client"
          item.action = lambda {|option| option[:action] = :add}
        end

        define(:delete) do |item|
          item.short = "-d"
          item.long = "--delete"
          item.desc = "delete a client"
          item.action = lambda {|option| option[:action] = :delete}
        end

        define(:list) do |item|
          item.short = "-l"
          item.long = "--list"
          item.desc = "list clients"
          item.action = lambda {|option| option[:action] = :list}
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
          item.desc = "client db path"
          item.action = lambda {|option, path| Global.relay_client_db_path = path}
        end

        validate do |option|
          abort("error: -a, -d, or -l") unless option[:action]
        end
      end

      prepare do
        # set client db
        Global.relay_client_db = RelayClientDB.new(Global.relay_client_db_path)

        # set name
        if [:add, :delete].include?(option[:action])
          option[:name] = HighLine.new.ask("Name: ") unless option[:name]
        end

        # set password
        if option[:action] == :add
          unless option[:password]
            option[:password] = HighLine.new.ask("Password: "){|q| q.echo = "*"}
            password = HighLine.new.ask("Re-enter password: "){|q| q.echo = "*"}
            abort("error: password mismatch") unless option[:password] == password
          end
        end
      end

      start do
        case option[:action]
        when :add
          Global.relay_client_db.add(option[:name], option[:password])
          Global.relay_client_db.save
        when :delete
          Global.relay_client_db.delete(option[:name])
          Global.relay_client_db.save
        when :list
          names = Global.relay_client_db.names
          puts "%s clients in %s" % [names.size, Global.relay_client_db_path]
          names.each {|user| puts user}
        end
      end
    end
  end
end
