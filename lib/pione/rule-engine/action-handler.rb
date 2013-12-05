module Pione
  module RuleEngine
    # ActionHandler handles ActionRule.
    class ActionHandler < BasicHandler
      def self.message_name
        "Action"
      end

      attr_reader :working_directory

      def initialize(*args)
        super(*args)
        @working_directory = Location[Global.working_directory_generator.mkdir]
        @env.variable_set(
          Lang::Variable.new("__WORKING_DIRECTORY__"),
          Lang::StringSequence.of(@working_directory.path.to_s)
        )
      end

      # Execute the action.
      def execute
        # prepare input files
        setup_working_directory
        # prepare shell script
        write_shell_script {|path| call_shell_script(path) }
        # collect outputs
        outputs = collect_outputs
        # write output data
        write_output_data(outputs)
        # write tuples
        write_output_tuples(outputs)
        # write environment info
        write_env_info
        # write other resources
        write_other_resources

        # clear working directory
        @working_directory.delete

        # return tuples
        return outputs
      end

      # Setup the variable table with working directory in addition.
      def setup_variable_table
        super

        @variable_table.set(Variable.new("__BASE__"), PioneString.new(base_location.uri).to_seq)
        @variable_table.set(Variable.new("_"), PackageExprSequence.new([PackageExpr.new(@rule.package_name)]))
      end

      # Synchronize input data into working directory.
      def setup_working_directory
        @inputs.flatten.each do |input|
          # get file path in working directory
          wd_location = @working_directory + input.name
          # create a link to cache
          cache_location = System::FileCache.get(input.location)
          wd_location.path.make_symlink(cache_location.path)
          unless wd_location.exist?
            raise RuleExecutionError.new(self)
          end
        end

        # FIXME: should not copy bin files in the package each time.
        bin = @base_location + "package" + "bin"
        if bin.exist?
          bin.entries.each do |entry|
            dest = @working_directory + "bin" + entry.basename
            unless dest.exist?
              entry.copy(dest)
              dest.path.chmod(0700)
            end
          end
        end
      end

      # Write the action into a shell script.
      def write_shell_script(&b)
        file = @working_directory + "__pione-action__.sh"

        # write the action
        if @dry_run
          @rule.outputs.flatten.each do |output|
            file.create("touch %s" % output.eval(@env).name)
          end
        else
          # apply offside rule
          content = @rule_definition.action_context.eval(@env).content
          file.create(Util::EmbededExprExpander.expand(@env, content))
          # chmod 700
          if @working_directory.scheme == "local"
            FileUtils.chmod(0700, file.path)
          end
        end

        # message
        lines = @rule_definition.action_context.eval(@env).content.split("\n")
        user_message(["-"*60, lines, "-"*60].flatten, 0, "SH")

        return b.call(file.path)
      end

      # Call shell script of the path.
      def call_shell_script(path)
        scriptname = File.basename(path)

        # stdout & stderr
        rule_condition = @rule_definition.rule_condition_context.eval(@env)
        output_conditions = rule_condition.outputs.map {|output| output.eval(@env)}
        stdout = output_conditions.find{|output| output.output_mode == :stdout}
        out = stdout ? stdout.pieces.first.pattern : ".stdout"
        err = ".stderr"

        # execute command
        `cd #{@working_directory.path}; PATH=#{(@working_directory + "bin").path}:$PATH ; ./#{scriptname} > #{out} 2> #{err}`

        # the case the script has errored
        unless $?.success?
          raise ActionError.new(self, digest, (@working_directory + err).read)
        end

        # delete .stdout file if it is empty
        if stdout.nil? and (@working_directory + out).size == 0
          (@working_directory + out).delete
        end

        # delete .stderr file if it is emtpy
        if (@working_directory + err).size == 0
          (@working_directory + err).delete
        end
      end

      # Make output tuple by name.
      def make_output_tuple_with_time(name)
        time = (@working_directory + name).mtime
        location = make_output_location(name)
        TupleSpace::DataTuple.new(name: name, domain: @domain_id, location: location, time: time)
      end

      # Collect output data by names from working directory.
      #
      # @return [void]
      def collect_outputs
        outputs = []
        filenames = @working_directory.file_entries.map{|entry| entry.path.basename.to_s}
        @rule_condition.outputs.each_with_index do |condition, i|
          _condition = condition.eval(@env)
          case _condition.distribution
          when :all
            outputs[i] = filenames.select{|name| _condition.match?(name)}.map do |name|
              make_output_tuple_with_time(name)
            end
          when :each
            if name = filenames.find {|name| _condition.match?(name)}
              outputs[i] = [make_output_tuple_with_time(name)]
            end
          end

          # apply touch operation
          if tuple = apply_touch_operation(_condition, outputs[i])
            outputs[i] = tuple
          end

          # write data null if needed
          write_data_null(_condition, outputs[i], i)
        end

        return outputs
      end

      # Write output data with caching.
      #
      # @return [void]
      def write_output_data(outputs)
        outputs.flatten.compact.each do |output|
          src = @working_directory + output.name
          dest = output.location
          System::FileCache.put(src, dest)
        end
      end

      # Write action environment information file.
      def write_env_info
        @env.variable_table.keys.map do |var|
          val = @env.variable_get(var)
          "%s: %s" % [var.name, val.textize]
        end.tap {|x| (@working_directory + ".pione-env").create(x.join("\n"))}
      end

      # Move other intermediate files to the domain location.
      def write_other_resources
        @working_directory.file_entries.each do |entry|
          location = make_location(entry.path.basename, @domain_id)
          begin
            entry.move(location)
          rescue => e
            Log::SystemLog.warn("cannot move %s to %s: %s" % [entry.path, location, e.message])
          end
        end
      end

      # Writes output tuples into the tuple space server.
      def write_output_tuples(outputs)
        outputs.flatten.compact.each {|output| write(output)}
      end
    end
  end
end
