require 'innocent-white/common'

module InnocentWhite

  # DataExp is a class for data name expression of rule input and output.
  class DataExp

    SEPARATOR = ':'

    # DataExp::Compiler is a regexp compiler for data expression.
    module Compiler
      TABLE = {}

      # Define a string matcher.
      def self.define_matcher(matcher, replace)
        TABLE[Regexp.escape(matcher)] = replace
      end

      # Asterisk symbol is multi-characters matcher(empty string is matched).
      define_matcher('*', '(.*)')

      # Question symbol is single character matcher(empty string is not matched).
      define_matcher('?', '(.)')

      # Compile data name into regular expression.
      def compile(name)
        return name unless name.kind_of?(String)

        s = "^#{Regexp.escape(name)}$"
        TABLE.keys.each {|key| s.gsub!(key, TABLE)}
        s.gsub!(/\\\[(!|\\\^)?(.*)\\\]/){"[#{'^' if $1}#{$2.gsub('\-','-')}]"}
        s.gsub!(/\\{(.*)\\}/){"(#{$1.split(',').join('|')})"}
        Regexp.new(s)
      end
      module_function :compile
    end

    # -- class --

    # Creates a name expression.
    def self.[](name)
      new(name)
    end

    # Creates a name expression with 'each' modifier.
    def self.each(name)
      new(name, :each)
    end

    # Create a name expression with 'all' modifier.
    def self.all(name)
      new(name, :all)
    end

    # Create a data name for stdout ouput.
    def self.stdout(name)
      new(name, :each, :stdout)
    end

    # Create a data name for stderr output.
    def self.stderr(name)
      new(name, :each, :stderr)
    end

    # Returns convertion prcedure for enumerable.
    def self.to_proc
      Proc.new{|name| name.kind_of?(self) ? name : self.new(name)}
    end

    # -- instance --

    attr_reader :name
    attr_reader :modifier
    attr_reader :mode
    attr_reader :exceptions

    def initialize(name, modifier = :each, mode = nil)
      raise ArgumentError.new(name) unless name.kind_of? String or name.kind_of? Regexp

      @name = name
      @modifier = modifier
      @mode = mode
      @exceptions = []
    end

    # Set it each modifier.
    def each
      @modifier = :each
      return self
    end

    # Set it all modifier.
    def all
      @modifier = :all
      return self
    end

    # Set it stdout mode.
    def stdout
      @mode = :stdout
      return self
    end

    # Set it stderr mode.
    def stderr
      @mode = :stderr
      return self
    end

    # Return a new expression expanded with the variables.
    def with_variables(variables)
      new_exp = self.class.new(Util.expand_variables(name, variables), @modifier)
      @exceptions.map{|exc| Util.expand_variables(exc.name, variables)}.each do |new_exc|
        new_exp.except(new_exc)
      end
      return new_exp
    end

    # Return true if the name has 'all' modifier.
    def all?
      @modifier == :all
    end

    # Return true if the name has 'exist' modifier.
    def each?
      @modifier == :each
    end

    # Return true if the data content is in stdout.
    def stdout?
      @mode == :stdout
    end

    # Return true if the data content is in stderr.
    def stderr?
      @mode == :stderr
    end

    # Set a exception and return self.
    def except(*names)
      @exceptions += names.map{|name| DataExp.new(name)}
      return self
    end

    # Return matched data if the name is matched with the expression.
    def match(other)
      # check exceptions
      return false if match_exceptions(other)
      # match test
      md = nil
      @name.split(SEPARATOR).each do |name|
        break if md = compile_to_regexp(name).match(other)
      end
      return md
    end

    # Select from name list matched with the expression.
    def select(*names)
      names.flatten.select {|name| match(name) }
    end

    # Generate concrete name string by arguments.
    # usage: DataExp["test-*.rb"].generate(1) # => "test-1.rb"
    def generate(*args)
      name = @name.clone
      while name =~ /(\*|\?)/ and not(args.empty?)
        val = args.shift.to_s
        name.sub!(/(\*|\?)/){$1 == "*" ? val : val[0]}
      end
      return name
    end

    # Return true if name, modifier, mode, and exceptions are the same.
    def ==(other)
      return false unless other.kind_of?(self.class)
      return false unless @name == other.name
      return false unless @modifier == other.modifier
      return false unless @mode == other.mode
      return false unless @exceptions.sort == other.exceptions.sort
      return true
    end

    alias eql? ==

    # Return hash value.
    def hash
      [@name, @modifier, @mode, @exceptions].join("\000").hash
    end

    # Same as Regexp#=~ but return 0 if it matched.
    def =~(other)
      match(other) ? 0 : nil
    end

    # Pattern match.
    def ===(other)
      match(other) ? true : false
    end

    private

    def compile_to_regexp(name)
      Compiler.compile(name)
    end

    def match_exceptions(name)
      not(@exceptions.select{|ex| ex.match(name)}.empty?)
    end
  end
end