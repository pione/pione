require 'tempfile'
require 'innocent-white/common'

module InnocentWhite
  module Rule
    RuleIO = Struct.new(:name, :value)

    # Base rule class for flow rule and action rule.
    class BaseRule
      attr_reader :inputs
      attr_reader :outputs
      attr_reader :params
      attr_reader :content

      #def initialize(rule_path, inputs, outputs, params, content)
      def initialize(inputs, outputs, params, content)
        @rule_path = rule_path
        @inputs = inputs
        @outputs = outputs
        @params = params
        @content = content
      end

      # Find input data from tuple space server.
      def find_inputs(ts_server, domain)
        _find_inputs(ts_server, domain, @inputs, 1, {})
      end

      # Find output data from tuple space server.
      def find_outputs(ts_server, domain, inputs)
        # FIXME
      end

      def make_task(ts_server)
        find_inputs(ts_server, domain).each do |_inputs|
          _outputs = find_outputs(ts_server, @domain)
          Tuple[:task].new(@rule_path, _inputs, outputs, params, content)
        end
      end

      private

      def _find_inputs(ts_server, domain, _inputs, index, var)
        return [[]] if _inputs.empty?

        # expand variables and compile to regular expression
        input = _inputs.first.to_regexp(var)

        # find an input from tuple space server
        tuples = _find_input(ts_server, domain, input)

        result = []

        if input.all?
          rest = _find_inputs(ts_server, domain, _inputs[1..-1], index+1, var.clone)
        else
          # find rest inputs recursively
          tuples.each do |tuple|
            make_auto_variables(input, index, tuple, var)
            rest = _find_inputs(ts_server, domain, _inputs[1..-1], index+1, var.clone)
            rest.each {|r| result << r.unshift(tuple) }
          end
        end

        return result
      end

      def _find_input(ts_server, domain, input_name)
        req = Tuple[:data].new(name: input_name, domain: domain)
        ts_server.read_all(req)
      end

      def make_auto_variables_by_exist(input, index, tuple, var)
        md = input.match(tuple.name)
        var["INPUT[#{index}].NAME]"] = tuple.name
        if tuple.value
          var["INPUT[#{index}].VALUE]"] = tuple.value
        else
          var["INPUT[#{index}].PATH"] = tuple.path
        end
        md.captures.each_with_index do |s, i|
          var["INPUT[#{index}].MATCH[#{i+1}]"] = s
        end
      end

    end

    class BaseHandler
      def initialize(rule, inputs, outputs, params, contents)
        # check arguments
        inputs.each do |i|
          unless i.respond_to?(:name) and i.respond_to?(:value)
            raise ArgumentError.new(inputs)
          end
        end
        raise ArugmentError unless inputs.size == inputs_definition.size

        @rule = rule
        @inputs = inputs
        @outputs = outputs
        @variable = {}
        @working_directory = Dir.mktmpdir
        setup_ouput_path(@outputs)
        make_auto_variables
      end

      private

      def setup_output_path(outputs)
        outputs.each do |output|
          case output
          when Tuple
            output.path = File.join(@tmpdir, output.name)
          when Array
            setup_output_path(output)
          end
        end
      end

      def update_outputs
        # FIXME: bad bad
        if not(outputs_definition.empty?)
          input = @inputs.first.name
          input_def = inputs_definition.first
          md = input_def.match(input)
          output_def = outputs_definition.first
          [output_def.gsub(/\{\$(\d)\}/){md[$1.to_i]}] # worst!
        else
          []
        end
      end

      def find_outputs
        list = Dir.entries(@working_directory)
        @rule.outputs.each_with_index do |exp, i|
          if exp.all?
            names = list.select {|elt| exp.match(elt)}
            @outputs[i]
          else
            list.each {|elt| exp.match(elt)}
          end
        end
      end

      def sysc_outputs
        
      end

      # Make input or output auto variables for 'exist' modified data name expression.
      def make_out_auto_variables_by_exist(type, exp, data, index)
        prefix = (type == :input ? "INPUT" : "OUTPUT") + "[#{index}]"
        @variable_table["#{prefix}.NAME]"] = name
        @variable_table["#{prefix}.VALUE]"] = 
        @variable_table["#{prefix}.PATH"] = data.path
        exp.match(data.name).captures.each_with_index do |s, i|
          @variable_table["#{prefix}.MATCH[#{i+1}]"] = s
        end
      end

      # Make auto vairables.
      def make_auto_variables
        # inputs
        @rule.inputs.each_with_index do |exp, index|
          make_io_auto_variables(:input, exp, @inputs[index], index)
        end

        # outputs
        @rule.outputs.each_with_index do |exp, index|
          make_io_auto_variables(:output, exp, @outputs[index], index)
        end

        # others
        make_other_auto_variables
      end

      # Make input or output auto variables.
      def make_io_auto_variables(type, exp, data, index)
        name = exp.all? ? :make_io_auto_variables_by_all : :make_io_auto_variables_by_exist
        method(name).call(type, exp, data, index)
      end

      # Make input or output auto variables for 'exist' modified data name expression.
      def make_io_auto_variables_by_exist(type, exp, data, index)
        prefix = (type == :input ? "INPUT" : "OUTPUT") + "[#{index}]"
        @variable_table["#{prefix}.NAME]"] = data.name
        @variable_table["#{prefix}.VALUE]"] = data.value
        @variable_table["#{prefix}.PATH"] = Resource.load(data.uri)
        exp.match(data.name).to_a.each_with_index do |s, i|
          @variable_table["#{prefix}.MATCH[#{i+1}]"] = s
        end
      end

      # Make input or output auto variables for 'all' modified data name expression.
      def make_io_auto_variables_by_all(type, exp, tuples, index)
        prefix = (type == :input ? "INPUT" : "OUTPUT") + "[#{index}]"
        @variable_table["#{prefix}.NAME"] = tuples.map{|t| t.name}.join(",")
      end

      # Make other auto variables.
      def make_other_auto_variables
        @variable_table["WORKING_DIRECTORY"] = @working_directory
        @variable_table["PWD"] = @working_directory
      end
    end

    class FlowRule < BaseRule
      def execute
        
      end
    end

    module FlowParts
      class Base < InnocentWhiteObject

      end

      class Call < Base
        attr_reader :rule_path

        def initialize(rule_path)
          @rule_path = rule_path
        end
      end

      class CallWithSync < Call; end

      class Condition
        attr_reader :condition
        attr_reader :true_expr
        attr_reader :false_expr
      end

      class Assignment
        attr_reader :variable
        attr_reader :content
      end
    end

    class ActionRule < BaseRule
      def execute
        write_shell_script {|path| shell path}
      end
    end

    class ActionHandler < BaseHandler
      def initialize(action, inputs, outputs, params)
        @action = action
        @inputs = inputs
        @outputs = outputs
        @params = params
        @variable = {}
        super
      end

      # Execute the action.
      def execute
        write_shell_script {|path| shell path}
      end

      private

      # Expand variables in the shell script.
      # when VAR_NAME := 1,
      # "__{$VAR_NAME}__" => "__a__"
      def expand_variables(content)
        content.gsub(/\{\$(.+?)\}/){@variable[$1]}
      end

      # Write shell script to the tempfile.
      def write_shell_script(&b)
        file = Tempfile.new(Util.uuid)
        file.print(expand_variables(self.class.content))
        file.close(false)
        return b.call(file.path)
      end

      # Call shell script of the path.
      def shell(path)
        sh = @variable["SHELL"] || "/bin/sh"
        `#{sh} #{path}`
      end
    end

  end
end
