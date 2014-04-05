module Rootage
  class Error < StandardError; end

  class ScenarioError < Error; end

  class CollectionError < Error; end

  # OptionError is raised when the command option is invalid.
  class OptionError < Error
    def initialize(cmd, msg)
      @cmd = cmd
      @msg = msg
    end

    def message
      'Option error for "%{name}": %{msg}' % {name: @cmd.name, msg: @msg}
    end
  end

  class ArgvError < Error; end

  class NoSuchItem < Error
    def initialize(scenario_name, sequence_name, item_name)
      @scenario_name = scenario_name
      @sequence_name = sequence_name
      @item_name = item_name
    end

    def arg
      {scenario: @scenario_name, sequence: @sequence_name, item: @item_name}
    end

    def message
      'Item "%{item}" not found at sequence "%{sequence}" in scenario "%{scenario}".' % arg
    end
  end

  # `PhaseTimeoutError` is raised when command phase exceeds time limit.
  class PhaseTimeoutError < Error
    attr_accessor :scenario_name
    attr_accessor :phase_name
    attr_accessor :action_name

    def initialize(scenario_name, phase_name, action_name=nil)
      @scenario_name = scenario_name
      @phase_name = phase_name
      @action_name = action_name
    end

    def message
      arg = {scnario: @scenario_name, phase: @phase_name, action: @action_name}
      '"%{scenario}" has timeouted at action "%{action}" in phase "%{phase}".' % arg
    end
  end

  # `NormalizerTypeError` is raised when the normalization type is
  # unknown. This error means that it's a PIONE's bug.
  class NormalizerTypeError < ScriptError
    def initialize(type)
      @type = type
    end

    def message
      'Normalization type "%s" is unknown.' % @type
    end
  end

  # `NormalizerValueError` is raised when the value cannot convert into the
  # normalization type.
  class NormalizerValueError < StandardError
    def initialize(type, value, detail)
      @type = type
      @value = value
      @detail = detail
    end

    def message
      case @type
      when Symbol
        '"%s" cannot normalize as "%s": %s' % [@value, @type, @detail]
      when Array
        '"%s" should be in the range of "%s".' % [@value, @type]
      else
        raise NormalizerTypeError.new(@type)
      end
    end
  end

  # UnknownLogLevel is raised when log level is unknown.
  class UnknownLogLevel < Error
    def initialize(klass, method_name, level)
      @klass = klass
      @method_name = method_name
      @level = level
    end

    def message
      "Log level %{level} is unknown in %{class}#%{method}" % args
    end

    private

    def args
      {:class => @klass, :method => @method_name, :level => @level}
    end
  end
end
