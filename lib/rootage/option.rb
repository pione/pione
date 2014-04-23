module Rootage
  # Option is an option item for PIONE command.
  class Option < Item
    # `type` is a normalization type. The string user specified is normalized
    # by this type.
    member :type

    # `range` is candidates of option values.
    member :range

    # `short` is an short option name. This requires first hyphen character
    # and successful one character. For example, `"-q"` is a short option.
    member :short

    # `long` is a long option name. This requires first hyphen characters and
    # any characters. For example, `"--quiet"` is a long option.
    member :long

    # `arg` is an option's argument. The notation of this follows
    # "optarg.rb". For example, `"ARG"` is requisite argument, and `"[ARG]"`
    # is optional argument.
    member :arg

    # Default value that the option is specified. This value is normalized by
    # option type.
    member :default

    # Initial model value. This value is normalized by option type.
    member :init

    # This validates option's value. Validation is done after application of
    # post process.
    member :validator

    # This flag is true, the option is requisite.
    member :requisite

    def define_validator(&b)
      self.validator = b
    end

    # Setup an OptionParser's option by this item.
    #
    # @param opt [OptionParser]
    #   option parser
    # @param cmd [Command::PlainCommand]
    #   command object
    # @return [void]
    def setup(opt, cmd)
      if not(arg.nil?) and type.nil?
        raise OptionError.new(cmd, "Option type is undefined for the option " + inspect)
      end

      # build OptionParser#on arguments
      args = [short_for_optparse, long_for_optparse, desc].compact

      # call #on with the argument
      opt.on(*args) {|val| specify(cmd, val)}
    end

    private

    # Return short option string for optparse.rb.
    def short_for_optparse
      (arg and long.nil?) ? ("%s %s" % [short, arg]) : short
    end

    # Return log option string for optparse.rb.
    def long_for_optparse
      (arg and not(long.nil?)) ? ("%s %s" % [long, arg]) : long
    end

    # Specify the option value.
    #
    # @param cmd [Command::PlainCommand]
    #   command object
    # @param val [Object]
    #   option value
    # @return [void]
    def specify(cmd, val)
      # set default value
      if val.nil? and not(self.default.nil?)
        val = self.default
      end

      # normalization
      if val
        val = Normalizer.normalize(type, val)
      end

      if range.nil? or range.include?(val)
        if processes.empty?
          cmd.model.specify(key, val)
        else
          execute(cmd, val)
        end
      else
        arg = {value: _val, range: range}
        raise OptionError.new(cmd, '"%{value}" is out of %{range}' % arg)
      end
    end
  end

  # OptionCollection is a collection interface for options.
  module OptionCollection
    include CollectionInterface
    set_item_class Option
  end

  # `OptionDefinition` is a class that holds command's option definitions.
  class OptionDefinition < Sequence
    include CollectionInterface
    set_item_class Option

    private

    # Parse the command options.
    #
    # @param cmd [Command]
    #   command object
    # @return [void]
    def execute_main(cmd)
      # append help option
      _list = list.clone
      _list << HelpOption.help

      _list.each do |item|
        # merge init values
        if item.init
          cmd.model[item.name] = Normalizer.normalize(item.type, item.init)
        end
        # set process context class
        if item.process_context_class.nil?
          item.process_context_class = get_process_context_class(cmd)
        end
      end

      # parse options
      OptionParser.new do |opt|
        _list.each {|item| item.setup(opt, cmd)}
      end.send(cmd.has_subcommands? ? :order! : :parse!, cmd.argv)

      # check option's validness
      check(cmd)
    rescue OptionParser::ParseError, NormalizerValueError => e
      raise OptionError.new(cmd, e.message)
    end

    # Check validness of the command options.
    def check(cmd)
      # check requisite options
      list.each do |item|
        if item.requisite and not(cmd.model[item.key])
          raise OptionError.new(cmd, 'option "%s" is requisite' % [item.long])
        end
      end
    end
  end
end
