module Pione
  module Command
    # PioneVal command enables you to get evaluation result of PIONE expressions from out of PIONE system.
    class PioneVal < BasicCommand
      #
      # basic informations
      #

      command_name "pione-val"
      command_banner "Get the evaluation result value of the PIONE expression."
      PioneCommand.add_subcommand("val", self)

      #
      # options
      #

      use_option :debug

      define_option(:domain_info) do |item|
        item.long = '--domain-info=LOCATION'
        item.desc = 'location of Domain info file'
        item.default = Location["./domain.dump"]
        item.value = lambda {|location| Location[location]}
      end

      #
      # command lifecycle: setup phase
      #

      setup :expression
      setup :domain_info

      # get expression string
      def setup_expression
        @str = @argv.first || abort("error: no expressions")
      end

      # Read a domain info file.
      def setup_domain_info
        if option[:domain_info].exist?
          @domain_info = System::DomainInfo.read(option[:domain_info])
        end
      end

      #
      # command lifecycle: execution phase
      #

      execute :evaluate
      execute :print

      # Evaluate expression string as PIONE expression.
      def execute_evaluate
        @val = Pione.val(@str, @domain_info)
      rescue Lang::UnboundError => e
        if option[:domain_info].exist?
          raise
        else
          abort("domain info file '%s' not found" % option[:domain_info].uri.to_s)
        end
      end

      # Print evaluation result.
      def execute_print
        $stdout.puts @val
      end
    end
  end
end

