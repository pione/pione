require 'tempfile'
require 'innocent-white/util'

module InnocentWhite
  module ProcessHandler
    class ModuleBase
      attr_reader :inputs
      attr_reader :outputs
      attr_reader :params

      def initialize
        @inputs = []
        @outputs = []
        @params = []
      end
    end

    class Rule < ModuleBase
      attr_reader :callers

      def initialize
        super()
        @sentences = []
        @callers = []
      end
    end

    class Action < ModuleBase
      attr_accessor :content
      attr_reader :variable

      def initialize(data={})
        super()
        @content = data[:content]
        @variable = Hash.new
      end

      def execute
        write_shell_script {|path| shell path}
      end

      private

      def expand_variables(content)
        @content.gsub(/\{\$(.+?)\}/){@variable[$1]}
      end

      def write_shell_script(&b)
        file = Tempfile.new(Util.uuid)
        file.print(expand_variables(@content))
        file.close(false)
        return b.call(file.path)
      end

      def shell(path)
        sh = @variable["SHELL"] || "/bin/sh"
        `#{sh} #{path}`
      end
    end

    class Caller
      def initialize(name, content)
        @name = name
        @content = content
      end

      def inputs
        
      end

      def outputs

      end

      def match(data)
        inputs.each do |input|
          input
        end
      end
    end
  end
end
