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
        option("-a", "--add", "add a client") do |data|
          data[:action] = :add
        end

        option("-d", "--delete", "delete a client") do |data|
          data[:action] = :delete
        end

        option("-l", "--list", "list clients") do |data|
          data[:action] = :list
        end

        option("-u name", "--user name", "user name") do |data, name|
          data[:name] = name
        end

        option("-p password", "--password password", "password") do |data, password|
          data[:password] = password
        end

        option("-f path", "--file path", "client db path") do |data, path|
          Global.relay_client_db_path = path
        end

        validate do |data|
          abort("error: -a, -d, or -l") unless data[:action]
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
