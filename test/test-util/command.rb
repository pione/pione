module TestUtil
  class CommandResult < StructX
    member :exception
    member :stdout
    member :stderr

    def success?
      exception.kind_of?(SystemExit) and exception.success?
    end

    def report
      unless success?
        puts "ERROR: %s" % exception.message
        exception.backtrace.each do |line|
          puts "TRACE: %s" % line
        end
        puts stdout.string[0..100] if stdout.string.size > 0
        puts stderr.string[0..100] if stderr.string.size > 0
      end
    end
  end

  module Command
    class << self
      def execute(&b)
        res = CommandResult.new(stdout: StringIO.new("", "w"), stderr: StringIO.new("", "w"))
        $stdout = res.stdout
        $stderr = res.stderr
        begin
          b.call
        rescue Object => e
          res.exception = e
        end
        $stdout = STDOUT
        $stderr = STDERR
        return res
      end

      def succeed(&b)
        res = execute(&b)
        res.report
        res.should.success
        return res
      end

      def fail(&b)
        res = execute(&b)
        res.should.not.success
        return res
      end
    end
  end
end