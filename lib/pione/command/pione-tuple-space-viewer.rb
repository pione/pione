module Pione
  module Command
    # PioneTupleSpaceView is a command that shows and searchs tuples in tuple
    # spaces.
    class PioneTupleSpaceViewer < BasicCommand
      define_info do
        set_name "pione-tuple-space-viewer"
        set_banner "Show and search tuples in tuple spaces."
      end

      define_option do
        default :identifiers, []
        default :exclusions, []

        option('-i', '--identifier=NAME', 'show tuples that have the identifier') do |data, name|
          data[:identifiers] << name
        end

        option('-e', '--exclude=NAME', 'exclude the tuple identifier') do |data, name|
          data[:exclusions] << name
        end

        option('--package=NAME', 'show tuples which domain has the package name') do |data, name|
          data[:package] = name
        end

        option('--rule=NAME', 'show tuples which domain has the rule name') do |data, name|
          data[:rule] = name
        end

        option('--rule-path=NAME', 'show tuples which domain has the rule path') do |data, path|
          data[:rule_path] = path
        end

        option('--data-name=NAME', 'show tuples that has the the name') do |data, name|
          data[:data_name] = name
        end

        option(
          '--type=TYPE',
          'show the bag which has the type("bag", "read_waiter", or "take_waiter")'
        ) do |data, bag_type|
          data[:bag_type] = bag_type.to_sym
        end

        option('--client=ADDRESS', 'druby address of target client process') do |data, address|
          data[:address] = address
        end
      end

      def initialize
        @tuple_space_servers = []
      end

      prepare do
        require 'pp'
        find_tuple_space_servers

        # tuple space servers are not found
        if @tuple_space_servers.empty?
          abort("No tuple space servers.")
        end
      end

      start do
        # print each bags
        @tuple_space_servers.each do |address, tuple_space_server|
          puts "TupleSpaceServer: %s" % Terminal.red(address)
          puts "-"*78
          if option[:bag_type] == :bag or option[:bag_type].nil?
            puts "*** bag ***"
            show_bag(tuple_space_server, :bag)
          end
          if option[:bag_type] == :read_waiter or option[:bag_type].nil?
            puts "*** read waiter ***"
            show_bag(tuple_space_server, :read_waiter)
          end
          if option[:bag_type] == :take_waiter or option[:bag_type].nil?
            puts "*** take waiter ***"
            show_bag(tuple_space_server, :take_waiter)
          end

          # summary
          puts "*** summary ***"
          puts "task: %s" % tuple_space_server.task_size
          puts "working: %s" % tuple_space_server.working_size
          puts "finished: %s" % tuple_space_server.finished_size
          puts "data: %s" % tuple_space_server.data_size
        end
      end

      private

      # Find tuple space servers.
      #
      # @return [void]
      def find_tuple_space_servers
        if option[:address]
          @tuple_space_servers << [option[:address], get_tuple_space_server(option[:address])]
        else
          find_tuple_space_servers_in_range
        end
      end

      # Find tuple space server in some port range. This scans ports of the address.
      #
      # @return [void]
      def find_tuple_space_servers_in_range
        Global.client_front_port_range.each do |port|
          begin
            address = "druby://%s:%s" % [Global.my_ip_address, port]
            @tuple_space_servers << [address, get_tuple_space_server(address)]
          rescue
            # ignore
          end
        end
      end

      # Get a tuple space server from the address.
      def get_tuple_space_server(address)
        ref = DRbObject.new_with_uri(address)
        ref.ping
        ref.tuple_space_server
      end

      # Show tuples of the typed bag in the tuple space server.
      #
      # @param tuple_space_server [TupleSpaceServer]
      #   tuple space server
      # @param type [Symbol]
      #   bag type
      # @return [void]
      def show_bag(tuple_space_server, type)
        tuple_space_server.all_tuples(type).each do |tuple|
          next if not(option[:identifiers].empty?) and not(option[:identifiers].include?(tuple.first.to_s))
          next if option[:exclusions].include?(tuple.first.to_s)

          t = Tuple.from_array(tuple)

          # rule_path
          if option[:rule_path]
            if t.respond_to?(:domain)
              next unless /^(#{option[:rule_path]})/.match(t.domain)
            else
              next
            end
          end

          # name
          if option[:data_name]
            if t.kind_of?(Tuple::Data) and t.respond_to?(:name)
              next unless Model::DataExpr.new(@data_name).match(t.name)
            else
              next
            end
          end

          # show
          res = PP.pp(tuple, "")
          res.gsub!(/\:[a-z]\w+/) {|s| Terminal.red(s) }
          res.gsub!(/\#<(\S+)/) {|s| "#<%s" % Terminal.green($1) }
          puts res
        end
      end
    end
  end
end
