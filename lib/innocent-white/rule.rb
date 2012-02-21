require 'tempfile'
require 'innocent-white/util'

module InnocentWhite
  module Rule
    RuleIO = Struct.new(:name, :value)

    # Compiler for nput string compiler
    module InputStringCompiler
      TABLE = {}

      def self.define_matcher(matcher, replace)
        TABLE[Regexp.escape(matcher)] = replace
      end

      define_matcher('*', '(.*)')
      define_matcher('+', '(.+)')

      def compile(input_string)
        Regexp.new(Regexp.escape(input_string).gsub(/\\\(\\\$([^)]+?)\\\)/){TABLE[$1]})
      end
      module_function :compile
    end

    # Base rule class for flow rule and action rule.
    class BaseRule
      attr_reader :inputs
      attr_reader :outputs
      attr_reader :params
      attr_reader :content
      attr_reader :variable

      def initialize(inputs, outputs, params, content)
        raise ArgumentError unless data.has_key?(:inputs)
        raise ArgumentError unless data.has_key?(:outputs)
        raise ArgumentError unless data.has_key?(:content)

        @inputs_definition = inputs
        @outputs_definition = outputs
        @params_definitioni = params
        @content = data[:content]
      end

      # find input data from tuple space server.
      def find_inputs(ts_server, domain)
        # FIXME: input handling is very poor now.
        @catched = @catched || []
        input_targets = @inputs.map {|input| Tuple[:data].new(name: input, path: domain)}
        Hash[@inputs.map {|input| [input, ts_server.read_all(data)]}]
        tuples = ts_server.read_all(data)
        tuple = tuples.select{|tuple| not(@catched.include?(tuple.name))}.first
        return nil if tuple.nil?
        begin
          @catched << tuple.name
          # FIXME
          return [RuleInput.new(tuple.name, tuple.raw)]
        rescue
          return nil
        end
      end

      def find_input(ts_server, domain, input)
        req = Tuple[:data].new(name: input.name, path: domain)
        tuples = ts_server.read_all(req)
        tuple = tuples.select{|tuple| 
      end
    end

    class BaseHandler
      def initialize(inputs=[], params={})
        # check arguments
        inputs.each do |i|
          unless i.respond_to?(:name) and i.respond_to?(:value)
            raise ArgumentError.new(inputs)
          end
        end
        raise ArugmentError unless inputs.size == inputs_definition.size

        # FIXME: bad
        @inputs = inputs
        @outputs = make_outputs

        # variable table
        @variable = params.clone
        make_auto_variables
      end

      private

      def inputs_definition
        @rule.inputs
      end

      def outputs_definition
        @rule.outputs
      end

      def make_outputs
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

      # Make auto-variables.
      def make_auto_variables
        # FIXME: bad bad bad
        @inputs.each_with_index do |input, i|
          @variable["INPUT_NAME[#{i}]"] = input.name
          @variable["INPUT_VALUE[#{i}]"] = input.value if input.value
        end
        @outputs.each_with_index do |output, i|
          @variable["OUTPUT_NAME[#{i}]"] = output.name
          # @variable["OUTPUT_VALUE"] = output.value
        end
      end
    end

    class FlowRule < BaseRule
      def execute
        
      end
    end

    module FlowParts
      class Caller
        attr_reader :rule_path
      end

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

      private

      def expand_variables(content)
        content.gsub(/\{\$(.+?)\}/){@variable[$1]}
      end

      def write_shell_script(&b)
        file = Tempfile.new(Util.uuid)
        file.print(expand_variables(self.class.content))
        file.close(false)
        return b.call(file.path)
      end

      def shell(path)
        sh = @variable["SHELL"] || "/bin/sh"
        `#{sh} #{path}`
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
