module Pione
  module Command
    # PioneVal command enables you to get evaluation result of PIONE expressions from out of PIONE system.
    class PioneVal < BasicCommand
      define_info do
        set_name "pione-val"
        set_banner "Get the evaluation result value of the PIONE expression."
      end

      define_option do
        use :debug

        define(:domain_info) do |item|
          item.long = '--domain-info=LOCATION'
          item.desc = 'location of Domain info file'
          item.default = Location["./domain.dump"]
          item.value = lambda {|location| Location[location]}
        end
      end

      start do
        # get expression string
        str = @argv.first || abort("no expressions")

        # setup domain info
        domain_info = nil
        if option[:domain_info].exist?
          domain_info = System::DomainInfo.read(option[:domain_info])
        end

        begin
          # evaluate it and print the result
          $stdout.puts Pione.val(str, domain_info)
          exit
        rescue Lang::UnboundError => e
          if option[:domain_info].exist?
            raise
          else
            abort("domain info file '%s' not found" % option[:domain_info].uri.to_s)
          end
        rescue => e
          abort("error: %s" % e)
        end
      end
    end
  end
end

