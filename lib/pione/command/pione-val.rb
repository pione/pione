module Pione
  module Command
    # PioneSyntaxChecker is a command for checking syntax tree and model of the
    # PIONE document.
    class PioneEval < BasicCommand
      define_info do
        set_name "pione-val"
        set_banner "Get the evaluation result value of the PIONE expression."
      end

      define_option do
        default :domain_info, Location["./domain.dump"]

        option('--domain-info=LOCATION', 'location of Domain info file') do |data, location|
          data[:domain_info] = Location[location]
        end
      end

      start do
        # get expression string
        str = ARGV[0] || abort("no expressions")

        # setup domain info
        domain_info = nil
        if option[:domain_info].exist?
          domain_info = System::DomainInfo.read(option[:domain_info])
        end

        begin
          # evaluate it and print the result
          $stdout.puts Pione.val(str, domain_info)
          exit
        rescue => e
          abort("error: %s" % e)
        end
      end
    end
  end
end

