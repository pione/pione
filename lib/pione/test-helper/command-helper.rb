module Pione
  module TestHelper
    # CommandResult is a result of command execution. This has result status,
    # stdout, stdin, and etc, so you can analyze and check it.
    class CommandResult < StructX
      member :exception
      member :stdout
      member :stderr

      # Return true if the command succeeded.
      def success?
        exception.kind_of?(SystemExit) and exception.success?
      end

      # Print the command result report.
      def report
        template = File.read(File.join(File.dirname(__FILE__), "command-result-report.erb"))
        Global.test_report.append(ERB.new(template, nil, "<>").result(binding))
      end
    end

    # This module helps tests of command execution.
    module Command
      class << self
        # Run the action with expectation command execution succeeds.
        def succeed(*options, &b)
          execute(options, &b).tap do |res|
            res.report if not(res.success?)
            res.should.success
          end
        end

        # Run the action with expectation command execution fails.
        def fail(*options, &b)
          execute(options, &b).tap do |res|
            res.report if res.success?
            res.should.not.success
          end
        end

        private

        # Run the command execution action.
        def execute(*options, &b)
          # initialize exit status
          Global.exit_status = true

          # make result
          res = CommandResult.new(stdout: StringIO.new("", "w"), stderr: StringIO.new("", "w"))

          # setup stdout and stderr
          $stdout = res.stdout unless options.include?(:show) or options.include?(:show_stdout)
          $stderr = res.stderr unless options.include?(:show) or options.include?(:show_stderr)

          # run the action
          begin
            b.call
          rescue Object => e
            unless options.include?(:show_exception)
              res.exception = e
            else
              raise
            end
          end

          # revert stdout and stderr
          $stdout = STDOUT
          $stderr = STDERR

          if options.include?(:report)
            res.report
          end

          return res
        end
      end
    end

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

        # with stand alone mode
        new(context: context, template: "%s with stand alone mode").tap do |runner|
          runner.default_arguments = ["-o", runner.base.path.to_s, "--stand-alone"]
          b.call(runner)
        end
      end

      def run(&b)
        _args = args
        _base = base
        context.it(template % title) do
          TestHelper::Command.succeed do
            Pione::Command::PioneClient.run(_args)
          end
          b.call(_base)
        end
      end

      def timeout(sec)
        _args = args + ["--timeout", sec.to_s]
        context.it(template % title) do
          TestHelper::Command.fail do
            Pione::Command::PioneClient.run(_args)
          end
        end
      end
    end
  end
end
