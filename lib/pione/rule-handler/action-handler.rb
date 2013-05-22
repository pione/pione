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
        @working_directory = Location[make_working_directory]
        @variable_table.set(Variable.new("__WORKING_DIRECTORY__"), PioneString.new(@working_directory.path.to_s).to_seq)
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
        super

        @variable_table.set(Variable.new("__BASE__"), PioneString.new(base_location.uri).to_seq)
        @variable_table.set(Variable.new("_"), PackageExprSequence.new([@rule.package_expr]))
      end

      # Make a working directory.
      #
      # @return [Pathname]
      #   path of working directory
      def make_working_directory
        # build directory path
        dirname = ID.domain_id(
          @rule.rule_expr.package_expr.name,
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
          wd_location.path.make_symlink(cache_location.path)
          unless wd_location.exist?
            raise RuleExecutionError.new(self)
          end
        end
      end

      # Write the data to the tempfile as shell script.
      def write_shell_script(&b)
        file = @working_directory + "__pione-action__.sh"
        if @dry_run
          @rule.outputs.flatten.each do |output|
            file.create("touch %s" % output.eval(@variable_table).name)
          end
        else
          # apply offside rule
          content = @rule.body.eval(@variable_table).content
          file.create(Util::Indentation.cut(content))
        end
        debug_message("Action #{file.path}")
        msgs = []
        msgs << "-"*60
        @rule.body.eval(@variable_table).content.split("\n").each {|line| msgs << line}
        msgs << "-"*60
        user_message(msgs, 0, "SH")
        if @working_directory.scheme == "local"
          FileUtils.chmod(0700, file.path)
        end
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
        `cd #{@working_directory.path}; ./#{scriptname} > #{out} 2> #{err}`

        # delete unneeded files
        if stdout.nil? and (@working_directory + out).size == 0
          (@working_directory + out).delete
        end
        if (@working_directory + err).size == 0
          (@working_directory + err).delete
        end
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
        filenames = @working_directory.file_entries.map{|entry| entry.path.basename.to_s}
        @rule.outputs.each_with_index do |output, i|
          output = output.eval(@variable_table)
          case output.distribution
          when :all
            @outputs[i] = filenames.select{|name| output.first.match(name)}.map do |name|
              make_output_tuple_with_time(name)
            end
          when :each
            if name = filenames.find {|name| output.first.match(name)}
              @outputs[i] = make_output_tuple_with_time(name)
            end
          end

          # apply touch operation
          if tuple = apply_touch_operation(output, @outputs[i])
            @outputs[i] = tuple
          end

          # write data null if needed
          write_data_null(output, @outputs[i], i)
        end
      end

      # Write output data with caching.
      #
      # @return [void]
      def write_output_data
        @outputs.flatten.compact.each do |output|
          src = @working_directory + output.name
          dest = output.location
          FileCache.put(src, dest)
        end
      end

      # Write action environment information file.
      #
      # @return [void]
      def write_env_info
        @variable_table.variables.map do |var|
          val = @variable_table.get(var)
          "%s: %s" % [var.name, val.textize]
        end.tap {|x| (@working_directory + ".pione-env").create(x.join("\n"))}
      end

      # Write resources for other intermediate files.
      #
      # @return [void]
      def write_other_resources
        @working_directory.file_entries.each do |entry|
          entry.move(make_location(entry.path.basename, @domain))
        end
      end

      # Writes output tuples into the tuple space server.
      def write_output_tuples
        @outputs.flatten.compact.each {|output| write(output)}
      end
    end
  end
end
