module Pione
  module Command
    class PioneRelayClientDB < BasicCommand
      set_program_name("pione-relay-client-db")

      define_option("-a", "--add", "add a client") do
        @action = :add
      end

      define_option("-d", "--delete", "delete a client") do
        @action = :delete
      end

      define_option("-l", "--list", "list clients") do
        @action = :list
      end

      define_option("-u name", "--user name", "user name") do |name|
        @name = name
      end

      define_option("-p password", "--password password", "password") do |password|
        @password = password
      end

      define_option("-f path", "--file path", "client db path") do |path|
        Global.relay_client_db_path = path
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
        # set client db
        Global.relay_client_db = RelayClientDB.new(Global.relay_client_db_path)

        # set name
        if [:add, :delete].include?(@action)
          @name = HighLine.new.ask("Name: ") unless @name
        end

        # set password
        if @action == :add
          unless @password
            @password = HighLine.new.ask("Password: "){|q| q.echo = "*"}
            password = HighLine.new.ask("Re-enter password: "){|q| q.echo = "*"}
            abort("error: password mismatch") unless @password == password
          end
        end
      end

      def start
        case @action
        when :add
          Global.relay_client_db.add(@name, @password)
          Global.relay_client_db.save
        when :delete
          Global.relay_client_db.delete(@name)
          Global.relay_client_db.save
        when :list
          names = Global.relay_client_db.names
          puts "%s clients in %s" % [names.size, Global.relay_client_db_path]
          names.each {|user| puts user}
        end
        terminate
      end
    end
  end
end
