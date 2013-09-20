module Pione
  module Command
    # PioneTupleSpaceView is a command that shows and searchs tuples in tuple
    # spaces.
    class PioneTupleSpaceViewer < BasicCommand
      #
      # basic informations
      #

      command_name "pione-tuple-space-viewer"
      command_banner "Show and search tuples in tuple spaces."

      #
      # command options
      #

      use_option :color
      use_option :debug

      define_option(:identifiers) do |item|
        item.short = '-i'
        item.long = '--identifier=NAME'
        item.desc = 'show tuples that have the identifier'
        item.default = []
        item.values = lambda {|name| name}
      end

      define_option(:exclusions) do |item|
        item.short = '-e'
        item.long = '--exclude=NAME'
        item.desc = 'exclude the tuple identifier'
        item.default = []
        item.values = lambda {|name| name}
      end

      define_option(:package) do |item|
        item.long = '--package=NAME'
        item.desc = 'show tuples which domain has the package name'
        item.value = lambda {|name| name}
      end

      define_option(:rule) do |item|
        item.long = '--rule=NAME'
        item.desc = 'show tuples which domain has the rule name'
        item.value = lambda {|name| name}
      end

      define_option(:rule_path) do |item|
        item.long = '--rule-path=NAME'
        item.desc = 'show tuples which domain has the rule path'
        item.value = lambda {|path| path}
      end

      define_option(:data_name) do |item|
        item.long = '--data-name=NAME'
        item.desc = 'show tuples that has the the name'
        item.value = lambda {|name| name}
      end

      define_option(:bag_type) do |item|
        item.long = '--type=TYPE'
        item.desc = 'show the bag which has the type("bag", "read_waiter", or "take_waiter")'
        item.value = lambda {|bag_type| bag_type.to_sym}
      end

      define_option(:address) do |item|
        item.long = '--client=ADDRESS'
        item.desc = 'druby address of target client process'
        item.value = lambda {|address| address}
      end

      #
      # instance methods
      #

      def initialize(*argv)
        super
        @tuple_spaces = []
      end

      #
      # command lifecycle: setup phase
      #

      setup :pp
      setup :tuple_space_servers

      def setup_pp
        require 'pp'
      end

      def setup_tuple_space_servers
        find_tuple_space_servers

        # tuple space servers are not found
        if @tuple_spaces.empty?
          abort("No tuple space servers.")
        end
      end

      #
      # command lifecycle: execution phase
      #

      execute :print_bag

      def execute_print_bag
        @tuple_space_servers.each do |address, tuple_space_server|
          puts "TupleSpaceServer: %s" % address.color(:red)
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

      #
      # helper methods
      #

      private

      # Find tuple spaces.
      def find_tuple_spaces
        if option[:address]
          @tuple_spaces << [option[:address], get_tuple_space_server(option[:address])]
        else
          find_tuple_spaces_in_range
        end
      end

      # Find tuple space server in some port range. This scans ports of the address.
      def find_tuple_spaces_in_range
        Global.client_front_port_range.each do |port|
          Util.ignore_exception do
            address = "druby://%s:%s" % [Global.my_ip_address, port]
            @tuple_spaces << [address, get_tuple_space_server(address)]
          end
        end
      end

      # Get a tuple space from the address.
      def get_tuple_space(address)
        ref = DRbObject.new_with_uri(address)
        ref.ping
        ref.get_tuple_space(nil)
      end

      # Show tuples of the typed bag in the tuple space server.
      def show_bag(tuple_space, type)
        tuple_space.all_tuples(type).each do |tuple|
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
              next unless Lang::DataExpr.new(@data_name).match(t.name)
            else
              next
            end
          end

          # show
          res = PP.pp(tuple, "")
          res.gsub!(/\:[a-z]\w+/) {|s| s.color(:red) }
          res.gsub!(/\#<(\S+)/) {|s| "#<%s" % $1.color(:green) }
          puts res
        end
      end
    end
  end
end
