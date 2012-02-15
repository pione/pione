require 'innocent-white/innocent-white-object'
require 'innocent-white/process-handler'

module InnocentWhite
  class Document < InnocentWhiteObject
    class ActionDefinition
      def self.eval(&b)
        obj = new
        obj.instance_eval(&b)
        return obj
      end

      def inputs(items)
        @inputs = items
      end

      def outputs(items)
        @outputs = items
      end

      def content(s)
        @content = s
      end

      def to_process_handler
        definition = {
          inputs: @inputs,
          outputs: @outputs,
          content: @content
        }
        ProcessHandler::Action.define(definition)
      end
    end

    def self.load(file)
      return eval(file.read).table
    end

    attr_reader :table

    def initialize(&b)
      @table = {}
      instance_eval(&b)
    end

    def define_action(path, &b)
      action = ActionDefinition.eval(&b).to_process_handler
      @table[path] = action
    end
  end
end
