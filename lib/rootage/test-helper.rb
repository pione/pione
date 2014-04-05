require 'rootage'

Thread.abort_on_exception = true

unless Rootage::Log.get_logger_block
  logger = Rootage::RubyStandardLogger.new
  Rootage::Log.set_logger_block {logger}
end

module Rootage
  def self.scope(&b)
    @scope_id = (@scope_id || 0) + 1
    mod = Module.new
    const_set("MODULE%s" % @scope_id, mod)
    mod.send(:define_method, :this) do
      mod
    end
    mod.instance_exec(mod, &b)
  end

  # `ScenarioResult` is a result of scenario execution. This has result status,
  # stdout, stdin, and etc, so you can analyze and check it.
  class ScenarioResult < StructX
    member :scenario
    member :model
    member :args
    member :stdout
    member :stderr
    member :exception

    # Return true if the scenario succeeded.
    def success?
      exception.nil? or (exception.kind_of?(SystemExit) and exception.success?)
    end

    # Print the scenario result report.
    def report
      template = File.read(File.join(File.dirname(__FILE__), "scenario-test-result.erb"))
      File.open("scenario-test-result.txt", "a") do |file|
        file.write(ERB.new(template, nil, "<>").result(binding))
      end
    end
  end

  # This module helps tests of command execution.
  module ScenarioTest
    class << self
      # Run the action, expecting scenario execution succeeds.
      def succeed(scenario, args=nil, &block)
        res = execute(scenario, args, &block)
        res.report if not(res.success?)
        res.success?.should.be.true
        return res
      end

      # Run the action, expecting scenario execution fails.
      def fail(scenario, args=nil, &block)
        res = execute(scenario, args, &block)
        res.report if res.success?
        res.should.not.success
        return res
      end

      private

      # Run the scenario.
      def execute(scenario, args=nil, &b)
        # make result
        _args = args ? args : scenario.args.clone
        stdout = StringIO.new("", "w")
        stderr = StringIO.new("", "w")
        res = ScenarioResult.new(
          scenario: scenario, args: _args, stdout: stdout, stderr: stderr
        )

        # setup stdout and stderr
        $stdout = stdout
        $stderr = stderr

        orig_logger_block = Log.get_logger_block
        null_logger = NullLogger.new
        Log.set_logger_block {null_logger}

        # run the action
        begin
          if block_given?
            b.call(scenario, args)
          else
            if scenario.is_a?(Scenario)
              scenario.run
            else
              scenario.run(args)
            end
          end
        rescue Object => e
          res.exception = e
        end

        # revert
        $stdout = STDOUT
        $stderr = STDERR
        Log.set_logger_block(&orig_logger_block)

        # kill childs
        Sys::ProcTable.ps.select {|ps|
          if ps.ppid == Process.pid
            Process.kill(:TERM, ps.pid)
          end
        }

        return res
      end
    end
  end
end
