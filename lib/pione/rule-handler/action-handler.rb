module Pione
  module RuleHandler
    # ActionHandler handles ActionRule.
    class ActionHandler < BaseHandler
      # Execute the action.
      def execute
        # prepare shell script
        stdout = write_shell_script {|path| call_shell_script(path) }
        # write output file if the handler is stdout mode
        write_output_file_from_stdout(stdout)
        # collect outputs
        collect_outputs
        # write resouces
        write_output_resources
        # write tuples
        write_output_tuples
        # return tuples
        return @outputs
      end

      private

      # Write the data to the tempfile as shell script.
      def write_shell_script(&b)
        file = File.open(File.join(@working_directory,"sh"), "w+")
        file.print(@rule.body.eval(@variable_table).content)
        if Pione.debug_mode?
          user_message ">>> #{file.path}"
          user_message "SH-----------------------------------------------------"
          user_message @rule.body.eval(@variable_table).content
          user_message "-----------------------------------------------------SH"
        end
        file.close
        FileUtils.chmod(0700, file.path)
        return b.call(file.path)
      end

      # Call shell script of the path.
      def call_shell_script(path)
        scriptname = File.basename(path)
        `cd #{@working_directory}; ./#{scriptname}`
      end

      # Write stdout data as output file if the handler is stdout mode.
      def write_output_file_from_stdout(stdout)
        @rule.outputs.each do |output|
          output = output.eval(@variable_table)
          if output.stdout?
            name = output.eval(@variable_table).name
            path = File.join(@working_directory, name)
            File.open(path, "w+") {|out| out.write stdout }
            break
          end
        end
      end

      # Make output tuple by name.
      def make_output_tuple_with_time(name)
        time = File.mtime(File.join(@working_directory, name))
        uri = (@resource_uri + name).to_s
        Tuple[:data].new(name: name, domain: @domain, uri: uri, time: time)
      end

      # Collect output data by names from working directory.
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

      # Write resources for output data.
      def write_output_resources
        @outputs.flatten.each do |output|
          val = File.read(File.join(@working_directory, output.name))
          Resource[output.uri].create(val)
        end
      end

      # Write output tuples into the tuple space server.
      def write_output_tuples
        @outputs.flatten.each {|output| write(output) }
      end
    end
  end
end
