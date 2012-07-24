module Pione
  module RuleHandler
    # ActionHandler handles ActionRule.
    class ActionHandler < BaseHandler
      # Execute the action.
      def execute
        stdout = write_shell_script {|path| call_shell(path) }
        write_stdout_as_output_file(stdout)
        collect_outputs
        write_output_resources
        write_output_tuples
        return @outputs
      end

      private

      # Write the data to the tempfile as shell script.
      def write_shell_script(&b)
        file = File.open(File.join(@working_directory,"sh"), "w+")
        file.print(@rule.body.eval(@variable_table).content)
        if debug_mode?
          user_message ">>> #{file.path}"
          user_message "SH-----------------------------------------------------"
          user_message @rule.body.eval(@variable_table).content
          user_message "-----------------------------------------------------SH"
        end
        file.close
        FileUtils.chmod(0700,file.path)
        return b.call(file.path)
      end

      # Call shell script of the path.
      def call_shell(path)
        scriptname = File.basename(path)
        `cd #{@working_directory}; ./#{scriptname}`
      end

      # Write stdout data as output file
      def write_stdout_as_output_file(stdout)
        @rule.outputs.each do |output|
          output = output.eval(@variable_table)
          if output.stdout?
            name = output.eval(@variable_table).name
            filepath = File.join(@working_directory, name)
            File.open(filepath, "w+") do |out|
              out.write stdout
            end
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
        @rule.outputs.each_with_index do |expr, i|
          expr = expr.eval(@variable_table)
          case expr.modifier
          when :all
            list.select{|elt| expr.match(elt)}.each do |name|
              unless name.empty?
                @outputs[i] = make_output_tuple_with_time(name)
              end
            end
          when :each
            if name = list.find {|elt| expr.match(elt)}
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
