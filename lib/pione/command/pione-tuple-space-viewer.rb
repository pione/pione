module Pione
  module Command
    # PioneTupleSpaceView is a command that shows and searchs tuples in tuple
    # spaces.
    class PioneTupleSpaceViewer < BasicCommand
      #
      # basic informations
      #

      define(:name, "pione-tuple-space-viewer")
      define(:desc, "Show and search tuples in tuple spaces")

      #
      # requirements
      #

      require :pp

      #
      # arguments
      #

      argument(:address) do |item|
        item.type = :location
        item.desc = "Tuple space address"
        item.missing = "You should set tuple space address"
      end

      #
      # options
      #

      option CommonOption.color
      option CommonOption.debug

      option(:identifiers) do |item|
        item.type  = :string
        item.short = '-i'
        item.long  = '--identifier'
        item.arg   = 'NAME'
        item.desc  = 'show tuples that have the identifier'

        item.assign do |val|
          (model[:identifiers] || []) << val
        end
      end

      option(:exclusions) do |item|
        item.type = :string
        item.short = '-e'
        item.long = '--exclude'
        item.arg  = 'NAME'
        item.desc = 'exclude the tuple identifier'

        item.assign do |val|
          (model[:exclusions] || []) << val
        end
      end

      option(:package) do |item|
        item.type = :string
        item.long = '--package'
        item.arg  = 'NAME'
        item.desc = 'show tuples which domain has the package name'
      end

      option(:rule) do |item|
        item.type = :string
        item.long = '--rule'
        item.arg  = 'NAME'
        item.desc = 'show tuples which domain has the rule name'
      end

      option(:rule_path) do |item|
        item.type = :string
        item.long = '--rule-path'
        item.arg  = 'NAME'
        item.desc = 'show tuples which domain has the rule path'
      end

      option(:data_name) do |item|
        item.type = :string
        item.long = '--data-name'
        item.arg  = 'NAME'
        item.desc = 'show tuples that has the the name'
      end

      option(:bag_type) do |item|
        item.type = :symbol
        item.long = '--type'
        item.arg  = 'TYPE'
        item.desc = 'show the bag which has the type("bag", "read_waiter", or "take_waiter")'
      end

      option(:address) do |item|
        item.type = :string
        item.long = '--client '
        item.arg  = 'ADDRESS'
        item.desc = 'druby address of target client process'
      end

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |item|
        item << :tuple_space
      end

      setup(:tuple_space) do |item|
        item.desc = "Setup tuple space"

        item.assign(:tuple_space) do
          get_tuple_space(model[:address])
        end

        # the tuple space not found
        item.process do
          test(model[:tuple_spaces].empty?)
          cmd.abort("No tuple space servers.")
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :print_bag
      end

      execution(:print_bag) do |item|
        item.desc = "Print tuples in bag"

        item.process do
          model[:tuple_spaces].each do |address, tuple_space_server|
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
      end
    end

    class PioneTupleSpaceViewerContext < Rootage::CommandContext
      # Get a tuple space from the address.
      def get_tuple_space(address)
        ref = DRbObject.new_with_uri(address)
        ref.ping
        ref.get_tuple_space(nil)
      rescue DRb::DRbConnError => e
        abort("cannot connect to %s: %s" % [address, e.message])
      end

      # Show tuples of the typed bag in the tuple space server.
      def show_bag(tuple_space, type)
        tuple_space.all_tuples(type).each do |tuple|
          next if not(option[:identifiers].empty?) and not(option[:identifiers].include?(tuple.first.to_s))
          next if option[:exclusions].include?(tuple.first.to_s)

          t = TupleSpace::Tuple.from_array(tuple)

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
            if t.kind_of?(TupleSpace::Data) and t.respond_to?(:name)
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

      PioneTupleSpaceViewer.define(:process_context_class, PioneTupleSpaceViewerContext)
    end
  end
end
