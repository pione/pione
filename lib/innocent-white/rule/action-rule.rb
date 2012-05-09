require 'innocent-white/common'

module InnocentWhite
  module Rule
    # ActionRule is a rule writing action.
    class ActionRule < BaseRule
      def action?
        true
      end

      def flow?
        false
      end
    end

    # ActionHandler handles ActionRule.
    class ActionHandler < BaseHandler
      # Execute the action.
      def execute
        stdout = write_shell_script {|path| shell path}
        write_output_from_stdout(stdout)
        find_outputs
        write_output_resource
        write_output_data
        return @outputs
      end

      private

      def write_output_from_stdout(stdout)
        @rule.outputs.each do |output|
          if output.stdout?
            name = output.with_variables(@variable_table).name
            filepath = File.join(@working_directory, name)
            File.open(filepath, "w+") do |out|
              out.write stdout
            end
            break
          end
        end
      end

      # Write the data to the tempfile as shell script.
      def write_shell_script(&b)
        file = File.open(File.join(@working_directory,"sh"), "w+")
        file.print(Util.expand_variables(@rule.content, @variable_table))
        if debug_mode?
          puts "[#{file.path}]"
          puts "SH-------------------------------------------------------"
          puts Util.expand_variables(@rule.content, @variable_table)
          puts "-------------------------------------------------------SH"
        end
        file.close
        FileUtils.chmod(0700,file.path)
        return b.call(file.path)
      end

      # Call shell script of the path.
      def shell(path)
        scriptname = File.basename(path)
        `cd #{@working_directory}; ./#{scriptname}`
      end

      # Find outputs data by those names from working directory.
      def find_outputs
        list = Dir.entries(@working_directory)
        @rule.outputs.each_with_index do |exp, i|
          exp = exp.with_variables(@variable_table)
          if exp.all?
            # case all modifier
            names = list.select {|elt| exp.match(elt)}
            unless names.empty?
              @outputs[i] = names.map{|name| make_output_tuple(name) unless name.empty?}
            end
          else
            # case each modifier
            name = list.find {|elt| exp.match(elt)}
            if name
              @outputs[i] = make_output_tuple(name)
            end
          end
        end
      end
    end
  end
end
