module Pione
  module Util
    # Util::Profiler is a customized profiler based on ruby-prof.
    module Profiler
      class << self
        @profile = false

        attr_reader :targets

        # Initialize profiler.
        def init
          # load ruby-prof
          require "ruby-prof"

          # set profiler variables
          @profile = true
          @reports = Array.new
          @targets = Array.new
          @date = Time.now.strftime("%Y%m%d%H%M%S")

          # set finalizer
          ::Kernel.at_exit { write_reports }
        end

        # Take profile within the block. If the report doesn't have available
        # target name, executed the block without profile.
        def profile(report, &b)
          if @profile and @targets.include?(report.name)
            report.result = RubyProf.profile(&b)
            @reports << report
          else
            yield
          end
        end

        # Write profile reports. They are generated at profile report
        # directory(see +Global.profile_report_directory+).
        def write_reports
          if @profile
            # create profile directory
            profile_dir = Global.profile_report_directory
            unless profile_dir.exist?
               profile_dir.mkdir
            end

            # generate reports
            @reports.group_by{|report| report.class}.each do |_, reports|
              reports.each_with_index do |report, i|
                path = profile_dir + ("%s_%s_%s_%d.txt" % [@date, Process.pid, report.name, i])
                path.open("w") do |out|
                  report.headers.each do |name, value|
                    out.puts "%s: %s" % [name, value]
                  end
                  out.puts "-" * 50
                  RubyProf::FlatPrinter.new(report.result).print(out, :min_percent => 1)
                end
              end
            end

            # clear reports
            @reports.clear
          end
        end
      end
    end

    # ProfileReport is a base report class. This provides report definition interface.
    class ProfileReport
      class << self
        def define_name(name)
          @name = name
        end

        def define_header(name, &b)
          @headers ||= Array.new
          @headers << [name, b]
        end
      end

      attr_accessor :result

      def name
        self.class.instance_variable_get(:@name)
      end

      def headers
        headers = self.class.instance_variable_get(:@headers) || []
        headers.map do |(name, proc)|
          [name, proc.call(self)]
        end
      end
    end

    # RuleApplicationProfileReport is a profile report for rule application.
    class RuleApplicationProfileReport < ProfileReport
      define_name "rule-application"
      define_header("Digest") {|report| report.digest }
      define_header("PID") { Process.pid }

      attr_reader :digest

      def initialize(digest)
        @digest = digest
      end
    end
  end
end
