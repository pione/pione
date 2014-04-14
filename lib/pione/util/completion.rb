module Pione
  module Util
    class Completion
      def self.compile(source, target)
        context = self.new.context
        target.write(ERB.new(source.read, nil, "-").result(context))
      end

      attr_reader :completion_command
      attr_reader :completion_exec
      attr_reader :name2
      attr_reader :name3

      def toplevel_commands(mod)
        mod.constants.map{|c| mod.const_get(c)}.select do |c|
          c.is_a?(Class) and c < Command::BasicCommand and c.toplevel?
        end.map {|cmd| [cmd.scenario_name, cmd]}
      end

      def context
        binding
      end

      def descendants(keys, cmd)
        if cmd.subcommand.empty?
          [[keys, cmd]]
        else
          cmd.subcommand.inject([[keys, cmd]]) do |list, (key, child)|
            _keys = keys + [key]
            if child.subcommand.empty?
              list << [_keys, child]
            else
              list.concat(descendants(_keys, child))
            end
          end
        end
      end
    end

    class BashCompletion < Completion
      def initialize
        @completion_command = "complete"
        @completion_exec = "complete -F"
        @name2 = "${COMP_WORDS[1]}"
        @name3 = "${COMP_WORDS[2]}"
      end

      def fun_subcommands(cmd)
        compreply(make_subcommands(cmd))
      end

      def fun_options(cmd)
        compreply(make_options(cmd))
      end

      private

      def compreply(options)
	'COMPREPLY=($(compgen -W "%s" -- "${COMP_WORDS[COMP_CWORD]}"));' % options
      end

      def make_subcommands(cmd)
        cmd.subcommand.keys.join(" ")
      end

      def make_options(cmd)
        items = cmd.option_definition.table.values
        items.sort{|a, b| a.long <=> b.long}.map{|item| item.long}.join(" ")
      end
    end

    class ZshCompletion < Completion
      def initialize
        @completion_command = "compdef"
        @completion_exec = "compdef"
        @name2 = "${words[2]}"
        @name3 = "${words[3]}"
      end

      def fun_subcommands(cmd)
        describe(cmd)
      end

      def fun_options(cmd)
        arguments(cmd)
      end

      private

      def describe(cmd)
        "list=(%s) _describe -t common-commands 'common commands' list;" % make_subcommands(cmd)
      end

      def arguments(cmd)
	"_arguments -s -S %s '*:file:_files' && return 0;" % make_options(cmd)
      end

      def make_subcommands(cmd)
        cmd.subcommand.map{|key, val| '%s:"%s"' % [key, val.desc]}.join(" ")
      end

      def make_options(cmd)
        items = cmd.option_definition.table.values
        items.sort{|a, b| a.long <=> b.long}.map do |item|
          name = item.long.gsub("[", "\\[").gsub("]", "\\]")
          "\"%s[%s]\"" % [name, item.desc]
        end.join(" ")
      end
    end
  end
end
