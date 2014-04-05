module Pione
  module TestHelper
    class PioneClientRunner < StructX
      member :title
      member :template, default: "%s"
      member :args
      member :base, default: lambda {Pione::Location[Temppath.mkdir]}
      member :default_arguments
      member :context

      def self.test(context, &b)
        # with client mode
        new(context: context).tap do |runner|
          runner.default_arguments = ["-o", runner.base.path.to_s]
          b.call(runner)
        end
      end

      def run(&b)
        _args = args
        _base = base
        context.it(template % title) do
          Rootage::ScenarioTest.succeed(Pione::Command::PioneClient, _args)
          b.call(_base)
        end
      end

      def fail
        _args = args
        context.it(template % title) do
          Rootage::ScenarioTest.fail(Pione::Command::PioneClient, _args)
        end
      end

      def timeout(sec)
        _args = args + ["--timeout", sec.to_s]
        context.it(template % title) do
          Rootage::ScenarioTest.fail(Pione::Command::PioneClient, _args)
        end
      end
    end
  end
end
