require 'innocent-white/common'

module InnocentWhite
  # DataNameExp is a class for input and ouput data name of rule.
  class DataNameExp

    # InnocentWhite::DataNameExp::Compiler is a compiler for data name string.
    module Compiler
      TABLE = {}

      # Define a string matcher.
      def self.define_matcher(matcher, replace)
        TABLE[Regexp.escape(matcher)] = replace
      end

      # Asterisk symbol is multi-character matcher(empty string is matched).
      define_matcher('*', '(.*)')

      # Question symbol is single character matcher(empty string is not matched).
      define_matcher('?', '(.)')

      # Compile data name into regular expression.
      def compile(name)
        return name unless name.kind_of?(String)
        s = "^#{Regexp.escape(name)}$"
        TABLE.keys.each do |key|
          s.gsub!(key, TABLE)
        end
        Regexp.new(s)
      end
      module_function :compile
    end

    # -- class --

    def self.[](name)
      new(name)
    end

    def self.each(name)
      new(name, :each)
    end

    # Create a name with 'all' modifier.
    def self.all(name)
      new(name, :all)
    end

    # Convert to proc object for Enumerator methods.
    def self.to_proc
      Proc.new{|name| self.new(name) }
    end

    # -- instance --

    attr_reader :name
    attr_reader :modifier
    attr_reader :exceptions

    def initialize(name, modifier = :each)
      @name = name
      @modifier = modifier
      @exceptions = []
    end

    # Return a new expression expanded with the variables.
    def with_variables(variables)
      new_exp = self.class.new(Util.expand_variables(name, variables), @modifier)
      @exceptions.map{|exc| exc.with_variable(variable)}.each do |new_exc|
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

    # Set a exception and return self.
    def except(*names)
      @exceptions += names.map{|name| DataNameExp[name]}
      return self
    end

    # Return matched data if the name is matched with the expression.
    def match(name)
      # check exceptions
      return false if match_exceptions(name)
      # match test
      compile_to_regexp(@name).match(name)
    end

    # Select from name list matched with the expression.
    def select(*names)
      names.flatten.select {|name| match(name) }
    end

    # Generate concrete name string by arguments.
    # usage: DataNameExp["test-*.rb"].generate(1) # => "test-1.rb"
    def generate(*args)
      name = @name.clone
      while name =~ /(\*|\?)/ and not(args.empty?)
        val = args.shift.to_s
        name.sub!(/(\*|\?)/){$1 == "*" ? val : val[0]}
      end
      return name
    end

    # Return true if name, modifier, and exceptions are same.
    def ==(other)
      return false unless other.kind_of?(self.class)
      @name == other.name && @modifier == other.modifier && @exceptions.sort == other.exceptions.sort
    end

    alias eql? ==

    # Return hash value.
    def hash
      "#{@name}\000#{@modifier}\000#{@exceptions}".hash 
    end

    # Same as Regexp#=~ but return 0 if it matched.
    def =~(other)
      match(other) ? 0 : nil
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
