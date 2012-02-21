require 'tempfile'
require 'innocent-white/util'

module InnocentWhite
  module Rule
    RuleIO = Struct.new(:name, :value)

    class Base

      # -- class --

      def self.define(data)
        raise ArgumentError unless data.has_key?(:inputs)
        raise ArgumentError unless data.has_key?(:outputs)
        raise ArgumentError unless data.has_key?(:content)

        klass = Class.new(self) do
          @inputs_definition = data[:inputs]
          @outputs_definition = data[:outputs]
          @params_definitioni = data[:params] || []
          @content = data[:content]
        end
      end

      # Return the inputs definition.
      def self.inputs_definition
        @inputs_definition
      end

      # Return the outputs definition.
      def self.outputs_definition
        @outputs_definition
      end

      # Return the parameters definition.
      def self.params_definition
        @params_definition
      end

      # Return the content.
      def self.content
        @content
      end

      # Catch input data from tuple space server.
      def self.catch_inputs(ts_server, call_path)
        # FIXME: input handling is very poor now.
        @catched = @catched || []
        input = inputs_definition.first
        data = Tuple[:data].new(name: input,
                                path: call_path)
        tuples = ts_server.read_all(data).map{|t| t.to_tuple}
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

      # -- instance --

      attr_reader :inputs
      attr_reader :outputs
      attr_reader :params
      attr_reader :variable

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
        self.class.inputs_definition
      end

      def outputs_definition
        self.class.outputs_definition
      end

      def make_outputs
        # FIXME: bad bad
        if not(self.class.outputs_definition.empty?)
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

    class FlowRule < Rule
      def execute
        
      end
    end

    module FlowParts
      class Caller
        attr_reader :rule_path
      end

      class Condition

      end

      class Assignment

      end
    end

    class ActionRule < Rule
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
  end
end
