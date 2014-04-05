module Pione
  module Command
    class PionePackageShow < BasicCommand
      #
      # informations
      #

      define(:name, "show")
      define(:desc, "Show the package informations")

      #
      # arguments
      #

      argument(:location) do |item|
        item.type    = :location
        item.desc    = "the package location that you want to show"
        item.missing = "There are no PIONE documents or packages."
      end

      #
      # options
      #

      option CommonOption.color
      option CommonOption.debug

      option(:advanced) do |item|
        item.type  = :boolean
        item.short = "-a"
        item.long  = "--advanced"
        item.desc  = "show advanced parameters"
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |seq|
        seq << :print_list
      end

      execution(:print_list) do |item|
        item.desc = "Print a list of parameters in the document"

        item.process do
          # read package
          package_handler = Package::PackageReader.read(model[:location])
          env = package_handler.eval(Lang::Environment.new)

          # print a list
          basic, advanced = Util::PackageParametersList.find(env, env.current_package_id)
          if basic.empty? and advanced.empty?
            puts "there are no user parameters in %s" % env.current_package_id
          else
            if not(basic.empty?)
              print_by_block("Basic Parameters", basic, env)
            end
            if not(advanced.empty?) and model[:advanced]
              print_by_block("Advanced Parameters", advanced, env)
            end
          end
        end

        item.exception(Package::InvalidPackage) do |e|
          cmd.abort("Package error: " + e.message)
        end

        item.exception(Lang::ParserError) do |e|
          cmd.abort("Pione syntax error: " + e.message)
        end

        item.exception(Lang::LangError) do |e|
          cmd.abort("Pione language error: %s(%s)" % [e.message, e.class.name])
        end
      end
    end

    # `PionePackageShowContext` is a context for `pione package show`.
    class PionePackageShowContext < Rootage::CommandContext
      # Print parameters by block.
      def print_by_block(header, params, env)
        unless params.empty?
          puts "%s:" % header
          params.each do |param|
            puts "  %s := %s" % [param.name, param.value.eval(env).textize]
          end
        end
      end
    end

    PionePackageShow.define(:process_context_class, PionePackageShowContext)

    PionePackage.define_subcommand("show", PionePackageShow)
  end
end
