module Pione
  module Log
    # DomainLog is a domain log that records domain inputs and parameters.
    class DomainLog
      include Sys # for Uname

      FILENAME = ".domain.log"

      forward_as_key! :@record, :system_name, :system_nodename, :system_machine, :system_version, :system_release

      # @return [Location::BasicLocation]
      #   domain's location
      attr_reader :domain_location

      # @return [Hash{String => String}]
      #   record table
      attr_reader :record

      # @param handler [RuleHandler::BasicHandler]
      #   rule handler
      def initialize(handler)
        @domain_location = handler.domain_location
        @record = {
          :system_name => Uname.sysname,
          :system_nodename => Uname.nodename,
          :system_machine => Uname.machine,
          :system_version => Uname.version,
          :system_release => Uname.release,
          :params => handler.param_set.textize,
          :inputs => inputs_string(handler.inputs),
          :domain => handler.domain_id,
          :domain_location => @domain_location.uri.to_s,
          :dry_run => handler.dry_run.to_s
        }
        if handler.respond_to?(:working_directory)
          @record[:working_directory] = handler.working_directory.location.uri.to_s
        end
      end

      # Save domain information file.
      #
      # @return [void]
      def save
        domain_info_location = @domain_location + FILENAME
        text = "== %s\n\n" % Time.now
        text << @record.map{|key, val| "- %s: %s" % [key,val]}.join("\n")
        text << "\n\n"
        if domain_info_location.exist?
          domain_info_location.append(text)
        else
          domain_info_location.create(text)
        end
      end

      private

      # Build a record string for inputs.
      #
      # @param inputs [Array<TupleSpace::DataTuple>]
      #   input tuples
      # @return [String]
      #   a record string
      def inputs_string(inputs)
        "\n%s" % inputs.map.with_index(1) do |input, i|
          if input.kind_of?(Array)
            input.map{|_input| input_data_string(_input, i)}.join("\n")
          else
            input_data_string(input, i)
          end
        end.join("\n")
      end

      # Build a data tuple string.
      #
      # @param input [TupleSpace::DataTuple]
      #   data tuple
      # @param i [Integer]
      #   index number
      def input_data_string(input, i)
        i = i.to_s
        sp1 = " "*4
        sp2 = " "*(6+i.size)
        args = [sp1, i, input.name, sp2, input.location.uri, sp2, input.timestamp]
        "%s%s. %s,\n%s%s,\n%s%s" % args
      end
    end
  end
end
