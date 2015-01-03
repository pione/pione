module Pione
  module RuleEngine
    # ActionHandler handles ActionRule.
    class ActionHandler < BasicHandler
      def self.message_name
        "Action"
      end

      attr_reader :working_directory

      def initialize(param)
        super(param)

        @working_directory = WorkingDirectory.new(@env, @base_location, @inputs)
      end

      # Execute the action.
      def execute
        # prepare input files
        @working_directory.import

        # call shell script
        script = ActionShellScript.new(@env, @working_directory, @rule_definition, @dry_run)
        sh = script.write
        user_message(["-"*60, sh.split("\n"), "-"*60].flatten, 0, "SH")
        result = script.call(@sesstion_id, @request_from, @client_ui)
        unless result
          # the case the script has errored
          raise ActionError.new(self, @digest, script.stderr.read)
        end

        # handle stdout mode of outputs
        copy_stdout_to_outputs(script.stdout)

        # collect outputs
        output_conditions = @rule_condition.outputs.map {|condition| condition.eval(@env)}
        outputs = @working_directory.collect_outputs(output_conditions).map.with_index do |names, i|
          tuples = names.map {|name| make_output_tuple_with_time(name)}

          # apply touch operation
          apply_touch_operation(output_conditions[i], tuples) || tuples
        end

        # write data null if needed
        outputs.each_with_index do |output, i|
          write_data_null(output_conditions[i], outputs[i], i)
        end

        # write output data
        write_output_data(outputs)
        # write tuples
        write_output_tuples(outputs)
        # write environment info
        write_env_info
        # write other resources
        write_other_resources

        # clear working directory
        @working_directory.close

        # return tuples
        return outputs
      end

      # Make output tuple by name.
      def make_output_tuple_with_time(name)
        time = (@working_directory.location + name).mtime
        location = make_output_location(name)
        TupleSpace::DataTuple.new(name: name, domain: @domain_id, location: location, time: time)
      end

      # Copy stdout file in the working directory to outputs.
      #
      # @param stdout [Location]
      #   stdout file
      # @return [void]
      def copy_stdout_to_outputs(stdout)
        if stdout.exist?
          @rule_condition.outputs.map do |output|
            condition = output.eval(@env)
            if condition.output_mode == :stdout
              condition.pieces.each do |piece|
                stdout.copy(@working_directory.location + piece.pattern)
              end
            end
          end
        end
      end

      # Write output data with caching.
      #
      # @return [void]
      def write_output_data(outputs)
        outputs.flatten.compact.each do |output|
          src = @working_directory.location + output.name
          dest = output.location
          System::FileCache.put(src, dest)
          # copy the data to the caller's domain in file server
          src.copy(dest)
        end
      end

      # Write action environment information file.
      def write_env_info
        @env.variable_table.keys.map do |var|
          val = @env.variable_get(var)
          "%s: %s" % [var.name, val.textize]
        end.tap {|x| (@working_directory.location + ".pione-env").create(x.join("\n"))}
      end

      # Move other intermediate files to the domain location.
      def write_other_resources
        @working_directory.location.file_entries.each do |entry|
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

    # WorkingDirectory is a directory that action rule executes the shell script.
    class WorkingDirectory
      def initialize(env, base_location, inputs)
        @env = env
        @dir = Location[Global.working_directory_generator.mkdir]
        @base_location = base_location
        @inputs = inputs
      end

      def location
        @dir
      end

      # Synchronize input data into working directory.
      def import
        @env.variable_set(
          Lang::Variable.new("__WORKING_DIRECTORY__"),
          Lang::StringSequence.of(@dir.path.to_s)
        )

        import_inputs
        import_bins
        import_etc
      end

      # Collect output data by names from working directory.
      #
      # @param output_conditions [Condition]
      #   all output conditions of action rule
      # @return [Array<Array<String>>]
      #   array of output filenames
      def collect_outputs(output_conditions)
        filenames = @dir.file_entries.map{|entry| entry.basename}
        output_conditions.map do |condition|
          case condition.distribution
          when :all
            filenames.select{|name| condition.match?(name)}
          when :each
            name = filenames.find {|name| condition.match?(name)}
            name ? [name] : []
          end
        end
      end

      # Clear the working directory.
      def close
        @dir.delete
      end

      private

      def import_inputs
        @inputs.flatten.each do |input|
          # get file path in working directory
          wd_location = @dir + input.name
          # create a link to cache
          cache_location = System::FileCache.get(input.location)
          wd_location.path.make_symlink(cache_location.path)
          unless wd_location.exist?
            raise RuleExecutionError.new(self)
          end
        end
      end

      def import_bins
        # FIXME: should not copy bin files in the package each time.
        bin = @base_location + "package" + "bin"
        if bin.exist?
          bin.entries.each do |entry|
            dest = @dir + "bin" + entry.basename
            unless dest.exist?
              # copy and set executable flag
              entry.copy(dest)
              dest.path.chmod(0700)
            end
          end
        end
      end

      def import_etc
        # FIXME: should not copy files in the package each time
        file_dir = @base_location + "package" + "etc"
        if file_dir.exist?
          file_dir.entries.each do |entry|
            dest = @dir + "etc" + entry.basename
            unless dest.exist?
              # copy and unset executable flag
              entry.copy(dest)
              dest.path.chmod(0600)
            end
          end
        end
      end
    end

    # ActionShellScript handles action rule's shell script.
    class ActionShellScript
      def initialize(env, working_directory, rule_definition, dry_run)
        @env = env
        @working_directory = working_directory
        @rule_definition = rule_definition
        @dry_run = dry_run
        @location = @working_directory.location + "__pione__.sh"
      end

      # Write the rule action into a shell script.
      #
      # @return [String]
      #   written shell script
      def write
        content = @rule_definition.action_context.eval(@env).content
        sh = Util::EmbededExprExpander.expand(@env, content)

        # write the action
        if @dry_run
          rule_condition = @rule_definition.rule_condition_context.eval(@env)
          rule_definition.outputs.flatten.each do |output|
            @location.append("touch %s" % output.eval(@env).pieces.first.pattern)
          end
        else
          @location.create(sh)
        end

        # chmod 700
        if @working_directory.location.scheme == "local"
          FileUtils.chmod(0700, @location.path)
        end

        return sh
      end

      # Call the shell script.
      #
      # @param session_id [String]
      #   session id
      # @param request_from [String]
      #   address of the client that task requested
      # @param client_ui [String]
      #   UI type of the client
      # @return [void]
      def call(session_id, request_from, client_ui)
        callee_env = {
          "PATH" => (@working_directory.location + "bin").path.to_s + ":" + ENV["PATH"],
          "PIONE_SESSION_ID" => session_id,
          "PIONE_REQUEST_FROM" => request_from.to_s,
          "PIONE_CLIENT_UI" => client_ui.to_s
        }
        command = "./#{@location.basename} > #{stdout.basename} 2> #{stderr.basename}"
        options = {:chdir => @working_directory.location.path.to_s}

        # execute command
        system(callee_env, command, options)

        result = $?.success?
        if result
          # delete .stderr and .stdout files if they are empty
          stdout.delete if stdout.size == 0
          stderr.delete if stderr.size == 0
        end
        return result
      #end
      end

      # Return the location of stdout file.
      #
      # @return [Location]
      #   location of stdout file
      def stdout
        @working_directory.location + ".stdout"
      end

      # Return the location of stderr file.
      #
      # @return [Locaiton]
      #   location of stderr file
      def stderr
        @working_directory.location + ".stderr"
      end
    end
  end
end
