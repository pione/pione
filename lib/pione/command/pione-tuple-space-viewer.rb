module Pione
  module Command
    class PioneTupleSpaceViewer < BasicCommand
      set_program_name("pione-tuple-space-viewer")

      define_option('-i', '--identifier=NAME', 'show tuples that have the identifier') do |name|
        @identifiers << name
      end

      define_option('-e', '--exclude=NAME', 'exclude the tuple identifier') do |name|
        @exclusions << name
      end

      define_option('--package=NAME', 'show tuples which domain has the package name') do |name|
        @package = name
      end

      define_option('--rule=NAME', 'show tuples which domain has the rule name') do |name|
        @rule = name
      end

      define_option('--rule-path=NAME', 'show tuples which domain has the rule path') do |path|
        @rule_path = path
      end

      define_option('--data-name=NAME', 'show tuples that has the the name') do |name|
        @data_name = name
      end

      define_option(
        '--type=TYPE',
        'show the bag which has the type("bag", "read_waiter", or "take_waiter")'
      ) do |bag_type|
        @bag_type = bag_type.to_sym
      end

      define_option('--client=ADDRESS', 'druby address of target client process') do |address|
        @address = address
      end

      def initialize
        @identifiers = []
        @exclusions = []
        @package = nil
        @rule = nil
        @rule_path = nil
        @data_name = nil
        @bag_type = nil
        @tuple_space_servers = []
      end

      def prepare
        require 'pp'
        find_tuple_space_servers

        # tuple space servers are not found
        if @tuple_space_servers.empty?
          abort("No tuple space servers.")
        end
      end

      def start
        # print each bags
        @tuple_space_servers.each do |address, tuple_space_server|
          puts "TupleSpaceServer: %s" % Terminal.red(address)
          puts "-"*78
          if @bag_type == :bag or @bag_type.nil?
            puts "*** bag ***"
            show_bag(tuple_space_server, :bag)
          end
          if @bag_type == :read_waiter or @bag_type.nil?
            puts "*** read waiter ***"
            show_bag(tuple_space_server, :read_waiter)
          end
          if @bag_type == :take_waiter or @bag_type.nil?
            puts "*** take waiter ***"
            show_bag(tuple_space_server, :take_waiter)
          end
        end
      end

      private

      def find_tuple_space_servers
        if @address
          @tuple_space_servers << [@address, get_tuple_space_server(@address)]
        else
          find_tuple_space_servers_in_range
        end
      end

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

      # Gets a tuple space server from the address.
      def get_tuple_space_server(address)
        ref = DRbObject.new_with_uri(address)
        ref.ping
        ref.tuple_space_server
      end

      def show_bag(tuple_space_server, type)
        tuple_space_server.all_tuples(type).each do |tuple|
          next if not(@identifiers.empty?) and not(@identifiers.include?(tuple.first.to_s))
          next if @exclusions.include?(tuple.first.to_s)

          t = Tuple.from_array(tuple)

          # rule_path
          if @rule_path
            if t.respond_to?(:domain)
              next unless /^(#{@rule_path})/.match(t.domain)
            else
              next
            end
          end

          # name
          if @data_name
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
