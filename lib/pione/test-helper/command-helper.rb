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
        unless success?
          puts "[FAIL]"
          puts "ERROR: %s" % exception.message
          exception.backtrace.each do |line|
            puts "TRACE: %s" % line
          end
          if stdout.string.size > 0
            puts "STDOUT:"
            puts stdout.string
          end
          if stderr.string.size > 0
            puts "STDERR:"
            puts stderr.string[0..100]
          end
        else
          puts "[SUCCESS]"
        end
      end
    end

    # This module helps tests of command execution.
    module Command
      class << self
        # Run the action with expectation command execution succeeds.
        def succeed(*options, &b)
          res = execute(options, &b)
          res.should.success
          return res
        end

        # Run the action with expectation command execution fails.
        def fail(*options, &b)
          res = execute(options, &b)
          res.should.not.success
          return res
        end

        private

        # Run the command execution action.
        def execute(options, &b)
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
  end
end
