module Rootage
  class Help
    # Known format table.
    FORMAT = {}

    # Register the help format. This is for subclasses.
    #
    # @param name [Symbol]
    #   format name
    # @param klass [Class]
    #   help class
    # @return [void]
    def self.register(name, klass=self)
      Help::FORMAT[name] = klass
    end

    # Find the named format.
    #
    # @param format [Symbol]
    #   format name
    # @return [Class]
    #   help class
    def self.find(format)
      Help::FORMAT[format]
    end

    attr_reader :cmd

    # @param [Command]
    #   command object that has this help
    def initialize(cmd)
      @cmd = cmd
    end

    private

    # Return argument items for the command.
    #
    # @return [Array<Argument>]
    #   arguments
    def arguments
      @cmd.argument_definition.table.values
    end

    # Return option items for the command. The result is sorted by long option
    # names.
    #
    # @return [Array<Option>]
    #   options
    def options
      @cmd.option_definition.table.values.sort{|a,b| a.long <=> b.long} + [HelpOption.help]
    end

    # Return the max width of subcommand headings.
    #
    # @return [Integer]
    #   max width of subcommand headings
    def subcommand_heading_width
      @cmd.subcommand.keys.max_by{|key| key.size}.size
    end

    # Return a heading of the argument item.
    #
    # @param arg [Command::ArgumentItem]
    #   an argument item
    # @return [String]
    #   a heading
    def argument_heading(arg)
      "<%s>" % (arg.heading || arg.name)
    end

    # Return max width size of argument headings.
    #
    # @return [Integer]
    #   max width
    def argument_heading_width
      arguments.max_by{|item| item.name.size}.name.size + 2
    end

    # Return a string of argument list.
    #
    # @return [String]
    #   argument list
    def argument_list
      arguments.map{|arg| argument_heading(arg)}.join(" ")
    end

    # Return a heading string for options help.
    #
    # @return [String]
    #   option heading string
    def option_heading(item)
      template = item.arg ? "%s #{item.arg}" : "%s"
      if item.short.nil?
        return template % item.long
      end
      if item.long.nil?
        return template % item.short
      end
      return template % "%s, %s" % [item.short, item.long]
    end

    # Return max width of option headings.
    #
    # @return [Integer]
    #   max width
    def option_heading_width
      option_heading(options.max_by{|item| option_heading(item).size}).size
    end
  end

  class TextHelp < Help
    register :txt

    def to_s
      src = File.read(File.join(File.dirname(__FILE__), "help.txt.erb"))
      ERB.new(src, nil, "-").result(binding)
    end
  end

  class MarkdownHelp < Help
    register :md

    def to_s
      src = File.read(File.join(File.dirname(__FILE__), "help.md.erb"))
      ERB.new(src, nil, "-").result(binding)
    end
  end

  # HelpOptionCollection is a item collection for help options.
  module HelpOption
    extend OptionCollection

    define(:help) do |item|
      item.type    = :symbol_downcase
      item.range   = [:txt, :md]
      item.long    = "--help"
      item.arg     = "[FORMAT]"
      item.desc    = "Show this help message"
      item.default = :txt

      item.process do |format|
        puts Help.find(format).new(cmd)
        cmd.exit
      end
    end
  end
end
