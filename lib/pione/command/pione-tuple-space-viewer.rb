module Pione
  module Command
    class PioneTupleSpaceViewer < BasicCommand
      set_program_name("pione-tuple-space-viewer")

      define_option('-t', '--target name', 'show only the tuple identifier') do |name|
        @targets << name
      end

      define_option('-e', '--exclude name', 'exclude the tuple identifier') do |name|
        @exclusions << name
      end

      def initialize
        @targets = []
        @exclusions = []
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
        @tuple_space_servers.each do |tuple_space_server|
          puts "TupleSpaceServer: %s" % Terminal.red(tuple_space_server.uuid)
          puts "-"*78
          puts "*** bag ***"
          show_bag(tuple_space_server, :bag)
          puts "*** read waiter ***"
          show_bag(tuple_space_server, :read_waiter)
          puts "*** take waiter ***"
          show_bag(tuple_space_server, :take_waiter)
        end
      end

      private

      def find_tuple_space_servers
        Global.client_front_port_range.each do |port|
          begin
            ref = DRbObject.new_with_uri("druby://localhost:%s" % port)
            ref.uuid
            @tuple_space_servers << ref.tuple_space_server
          rescue
          end
        end
      end

      def show_bag(tuple_space_server, type)
        tuple_space_server.all_tuples(type).each do |tuple|
          next if not(@targets.empty?) and not(@targets.include?(tuple.first.to_s))
          next if @exclusions.include?(tuple.first.to_s)

          res = PP.pp(tuple, "")
          res.gsub!(/\:[a-z]\w+/) {|s| Terminal.red(s) }
          res.gsub!(/\#<(\S+)/) {|s| "#<%s" % Terminal.green($1) }
          puts res
        end
      end
    end
  end
end
