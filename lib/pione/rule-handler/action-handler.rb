module Pione
  module RuleHandler
    # ActionHandler handles ActionRule.
    class ActionHandler < BasicHandler
      def self.message_name
        "Action"
      end

      attr_reader :working_directory

      def initialize(*args)
        super(*args)
        @working_directory = make_working_directory
        setup_variable_table
      end

      # Execute the action.
      def execute
        # prepare input files
        setup_working_directory
        # prepare shell script
        write_shell_script {|path| call_shell_script(path) }
        # collect outputs
        collect_outputs
        # write output data
        write_output_data
        # write tuples
        write_output_tuples
        # write environment info
        write_env_info
        # write other resources
        write_other_resources

        # return tuples
        return @outputs
      end

      private

      # Setup the variable table with working directory in addition.
      def setup_variable_table
        unless @working_directory
          super
        else
          @variable_table.set(
            Variable.new("WORKING_DIRECTORY"),
            PioneString.new(@working_directory)
          )
          @variable_table.set(
            Variable.new("PWD"),
            PioneString.new(@working_directory)
          )
        end
      end

      # Make a working directory.
      #
      # @return [Pathname]
      #   path of working directory
      def make_working_directory
        # build directory path
        dirname = ID.domain_id(
          @rule.rule_expr.package.name,
          @rule.rule_expr.name,
          @inputs,
          @original_params
        )

        # create a directory
        return (Global.working_directory + dirname).tap{|path| path.mkpath}
      end

      # Synchronize input data into working directory.
      def setup_working_directory
        @inputs.flatten.each do |input|
          # get file path in working directory
          wd_location = @working_directory + input.name
          # create a link to cache
          cache_location = FileCache.get(input.location)
          wd_location.make_symlink(cache_location.path)
          unless wd_location.exist?
            raise RuleExecutionError.new(self)
          end
        end
      end

      # Write the data to the tempfile as shell script.
      def write_shell_script(&b)
        file = File.open(
          File.join(@working_directory,"__pione-action__.sh"),
          "w+"
        )
        if @dry_run
          @rule.outputs.flatten.each do |output|
            file.puts("touch %s" % output.eval(@variable_table).name)
          end
        else
          file.print(@rule.body.eval(@variable_table).content)
        end
        debug_message("Action #{file.path}")
        user_message("-"*60, 0, "SH")
        @rule.body.eval(@variable_table).content.split("\n").each do |line|
          user_message(line, 0, "SH")
        end
        user_message("-"*60, 0, "SH")
        file.close
        FileUtils.chmod(0700, file.path)
        return b.call(file.path)
      end

      # Call shell script of the path.
      def call_shell_script(path)
        scriptname = File.basename(path)

        # stdout & stderr
        stdout = @rule.outputs.map {|output|
          output.eval(@variable_table)
        }.find {|output| output.stdout?}
        out = stdout ? stdout.name : ".stdout"
        err = ".stderr"

        # execute command
        `cd #{@working_directory}; ./#{scriptname} > #{out} 2> #{err}`
      end

      # Make output tuple by name.
      def make_output_tuple_with_time(name)
        time = (@working_directory + name).mtime
        location = make_output_location(name)
        Tuple[:data].new(name: name, domain: @domain, location: location, time: time)
      end

      # Collect output data by names from working directory.
      #
      # @return [void]
      def collect_outputs
        list = Dir.entries(@working_directory)
        @rule.outputs.each_with_index do |output, i|
          output = output.eval(@variable_table)
          case output.modifier
          when :all
            @outputs[i] = list.select{|name| output.match(name)}.map do |name|
              make_output_tuple_with_time(name)
            end
          when :each
            if name = list.find {|name| output.match(name)}
              @outputs[i] = make_output_tuple_with_time(name)
            end
          end
        end
      end

      # Write output data with caching.
      #
      # @return [void]
      def write_output_data
        @outputs.flatten.compact.each do |output|
          src = Location[@working_directory + output.name]
          dest = output.location
          FileCache.put(src, dest)
        end
      end

      # Write action environment information file.
      #
      # @return [void]
      def write_env_info
        (@working_directory + ".pione-env").open("w+") do |out|
          @variable_table.variables.each do |var|
            val = @variable_table.get(var)
            out.puts "%s: %s" % [var.name, val.textize]
          end
        end
      end

      # Write resources for other intermediate files.
      #
      # @return [void]
      def write_other_resources
        @working_directory.entries.each do |name|
          path = @working_directory + name
          if File.ftype(path) == "file"
            Location[path].move(make_location(name, @domain))
          end
        end
      end

      # Writes output tuples into the tuple space server.
      def write_output_tuples
        @outputs.flatten.compact.each {|output| write(output)}
      end
    end
  end
end
