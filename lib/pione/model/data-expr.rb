module Pione
  module Model
    # DataExpr is a class for data name expressions of rule input and output.
    #
    # @example
    #   # complete name
    #   DataExpr.new("test.txt")
    # @example
    #   # incomplete name
    #   DataExpr.new("*.txt")
    class DataExpr < BasicModel

      # separator symbol for all modifier
      SEPARATOR = ':'

      # DataExpr::Compiler is a regexp compiler for data expression.
      module Compiler
        TABLE = {}

        # Define a string matcher.
        def self.define_matcher(matcher, replace)
          TABLE[Regexp.escape(matcher)] = replace
        end

        # Asterisk symbol is multi-characters matcher(empty string is not matched).
        define_matcher('*', '(.+)')

        # Question symbol is single character matcher(empty string is not matched).
        define_matcher('?', '(.)')

        # Compiles data name into regular expression.
        #
        # @param name [String]
        #   data name
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

      class << self
        alias :orig_new :new

        # Create a data expression. If the name includes separators, create DataExprOr instance.
        def new(*args)
          # check OR expression
          name = args.first
          if self == DataExpr and name.include?(SEPARATOR)
            name.split(SEPARATOR).map do |single_name|
              orig_new(single_name, *args.drop(1))
            end.tap {|exprs| return DataExprOr.new(*exprs)}
          end

          # other cases
          return orig_new(*args)
        end

        # Create a named expression.
        #
        # @param name [String]
        #   data name
        def [](name)
          new(name)
        end

        # Create a name expression with 'each' modifier.
        #
        # @param name [String]
        #   data name
        def each(name)
          new(name, modifier: :each)
        end

        # Create a name expression with 'all' modifier.
        #
        # @param name [String]
        #   data name
        def all(name)
          new(name, modifier: :all)
        end

        # Create a new data name for stdout ouput.
        #
        # @param name [String]
        #   data name
        # @return [DataExpr]
        #   data expression for stdout
        def stdout(name)
          new(name, modifier: :each, mode: :stdout)
        end

        # Create a new data name for stderr output.
        #
        # @param name [String]
        #   data name
        # @return [DataExpr]
        #   data expression for stderr
        def stderr(name)
          new(name, modifier: :each, mode: :stderr)
        end

        # Return convertion prcedure for enumerable.
        #
        # @return [Proc]
        #   +Proc+ object that returns data expression with name
        def to_proc
          Proc.new{|name| name.kind_of?(self) ? name : self.new(name)}
        end
      end

      set_pione_model_type TypeDataExpr

      attr_reader :name
      forward_as_key! :@data, :modifier, :mode, :exceptions, :update_criteria

      # Create a data expression.
      #
      # @param name [String]
      #   data expression name
      # @param opts [Hash] options of the expression
      # @option opts [Symbol] :modifier
      #   :all or :each
      # @option opts [Symbol] :mode
      #   nil, :stdout, or :stderr
      # @option opts [Array<DataExpr>] :exceptions
      #   exceptional expressions
      # @option opts [Boolean] :update_criteria
      #   the flag whether the data disregards update criterias
      def initialize(name, data={})
        unless name.kind_of? String or name.kind_of? Regexp
          raise ArgumentError.new(name)
        end

        @name = name
        @data = Hash.new
        @data[:modifier] = data[:modifier] || :each
        @data[:mode] = data[:mode]
        @data[:exceptions] = data[:exceptions] || []
        @data[:update_criteria] = data[:update_criteria] || :care

        super()
      end

      # Return new data expression with each modifier.
      #
      # @return [DataExpr]
      #   new data expression with each modifier
      def each
        return self.class.new(@name, @data.merge(modifier: :each))
      end

      # Return new data expression with all modifier.
      #
      # @return [DataExpr]
      #   new data expression with all modifier
      def all
        return self.class.new(@name, @data.merge(modifier: :all))
      end

      # Return new data expression with stdout mode.
      #
      # @return [DataExpr]
      #   new data expression with stdout mode
      def stdout
        return self.class.new(@name, @data.merge(mode: :stdout))
      end

      # Return new data expression with stderr mode.
      #
      # @return [DataExpr]
      #   new data expression with stderr mode
      def stderr
        return self.class.new(@name, @data.merge(mode: :stderr))
      end

      # Return new data expression with disregarding update-criteria.
      #
      # @return [DataExpr]
      #    new data expression with disregarding update-criteria
      def neglect
        return self.class.new(@name, @data.merge(update_criteria: :neglect))
      end

      # Return new data expression with regarding update-criteria.
      #
      # @return [DataExpr]
      #    new data expression with regarding update-criteria
      def care
        return self.class.new(@name, @data.merge(update_criteria: :care))
      end

      # Evaluate the data expression.
      #
      # @param vtable [VariableTable]
      #   variable table for evaluation
      # @return [BasicModel]
      #   evaluation result
      def eval(vtable)
        new_exceptions = exceptions.map {|exc| exc.eval(vtable)}
        self.class.new(vtable.expand(name), @data.merge(exceptions: new_exceptions))
      end

      # Return true if the name includes variables.
      #
      # @return [Boolean]
      #   true if the name includes variables
      def include_variable?
        VariableTable.check_include_variable(name)
      end

      # @api private
      def task_id_string
        "DataExpr<#{name},#{modifier},[%s]>" % [
          exceptions.map{|exc| exc.task_id_string}.join(",")
        ]
      end

      # @api private
      def textize
        "data_expr(\"#{name}\",:#{modifier},[%s])" % [
          exceptions.map{|exc| exc.textize}.join(",")
        ]
      end

      # Return true if the name has 'all' modifier.
      #
      # @return [Boolean]
      #   true if the name has 'all' modifier
      def all?
        modifier == :all
      end

      # Return true if the name has 'each' modifier.
      #
      # @return [Boolean]
      #   true if the name has 'each' modifier
      def each?
        modifier == :each
      end

      # Return true if the data content is in stdout.
      #
      # @return [Boolean]
      #   true if the data content is in stdout
      def stdout?
        mode == :stdout
      end

      # Return true if the data content is in stderr.
      #
      # @return [Boolean]
      #   true if the data content is in stderr
      def stderr?
        mode == :stderr
      end

      # Return true if the data disregards update criteria.
      #
      # @return [Boolean]
      #   true if the data disregards update criteria
      def neglect?
        update_criteria == :neglect
      end

      # Return true if the data regards update criteria.
      #
      # @return [Boolean]
      #   true if the data regards update criteria
      def care?
        update_criteria == :care
      end

      # Create new data expression with a exception name.
      #
      # @param exc [DataExpr, String]
      #   data name for exceptions
      # @return [DataExpr]
      #   new data name with the exception
      def except(exc)
        new_exceptions = exceptions + [exc.kind_of?(DataExpr) ? exc : DataExpr.new(exc)]
        return self.class.new(name, @data.merge(exceptions: new_exceptions))
      end

      # Return matched data if the name is matched with the expression.
      #
      # @param other [String]
      #   data name string
      # @return [MatchedData]
      #   matched data
      def match(other)
        # check exceptions
        return false if match_exceptions(other)
        # match test
        return compile_to_regexp(name).match(other)
      end

      # Return if the expression accepts nonexistence of corresponding data.
      #
      # @return [Boolean]
      #   false because data expression needs corresponding data
      def accept_nonexistence?
        false
      end

      # Select from name list matched with the expression.
      #
      # @param [Array<String>] names
      #   name list
      def select(*names)
        names.flatten.select {|name| match(name) }
      end

      # Generate concrete name string by arguments.
      #
      # @example
      #   DataExpr["test-*.rb"].generate(1)
      #   # => "test-1.rb"
      def generate(*args)
        name = @name.clone
        while name =~ /(\*|\?)/ and not(args.empty?)
          val = args.shift.to_s
          name.sub!(/(\*|\?)/){$1 == "*" ? val : val[0]}
        end
        return name
      end

      # Create OR relation data expression. Self and the other element have the
      # same attributes.
      #
      # @example
      #   expr = DataExpr.new("A") | DataExpr.new("B")
      #   expr.match("A") # => true
      #   expr.match("B") # => true
      #   expr.match("C") # => false
      # @example
      #   DataExpr.all("A") | DataExpr.each("B")
      #   # => raise ArgumentError
      def |(other)
        raise ArgumentError.new(other) unless other.kind_of?(DataExpr)
        return DataExprOr.new(self, other)
      end

      # @api private
      def to_s
        "#<#<#{self.class.name}> name='#{name}' data=#{@data.inspect}>"
      end

      # Return true if name, modifier, mode, and exceptions are the same.
      #
      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        return false unless name == other.name
        return false unless modifier == other.modifier
        return false unless mode == other.mode
        return false unless exceptions.sort == other.exceptions.sort
        return true
      end
      alias :eql? :"=="

      # @api private
      def hash
        [name, modifier, mode, exceptions].join("\000").hash
      end

      # Same as Regexp#=~ but return 0 if it matched.
      def =~(other)
        match(other) ? 0 : nil
      end

      # Pattern match.
      #
      # @api private
      def ===(other)
        match(other) ? true : false
      end

      private

      # @api private
      def compile_to_regexp(name)
        Compiler.compile(name)
      end

      # Return true if the name matchs exceptions.
      #
      # @api private
      def match_exceptions(name)
        not(exceptions.select{|ex| ex.match(name)}.empty?)
      end
    end

    class DataExprNull < DataExpr
      include Singleton

      def initialize
        @data = {}
      end

      def accept_nonexistence?
        true
      end

      def match(name)
        nil
      end

      # Evaluate the data expression. The result is myself.
      #
      # @param vtable [VariableTable]
      #   variable table for evaluation
      # @return [BasicModel]
      #   self
      def eval(vtable)
        self
      end

      def textize
        "data_expr(null)"
      end

      # @api private
      def to_s
        "#<#<#{self.class.name}>>"
      end

      # @api private
      def ==(other)
        self.class == other.class
      end
      alias :eql? :"=="
    end

    # DataExprOr represents or-relation of data expressions. Expressions have
    # same properties about modifier and mode.
    class DataExprOr < DataExpr
      attr_reader :elements

      forward! Proc.new{find_not_null_element}, :modifier, :mode, :update_criteria

      # @param args [Array<DataExpr>]
      #   elements that have OR relation
      def initialize(*args)
        @elements = args

        # check whether all elements have same modifier
        unless args.all?{|arg| find_not_null_element.modifier == arg.modifier or arg.kind_of?(DataExprNull)}
          raise ArgumentError.new(args)
        end

        # check whether all elements have same mode
        unless args.all?{|arg| args.first.mode == arg.mode or arg.kind_of?(DataExprNull)}
          raise ArmguentError.new(args)
        end

        # check whether all elements have same mode
        unless args.all?{|arg| args.first.update_criteria == arg.update_criteria or arg.kind_of?(DataExprNull)}
          raise ArmguentError.new(args)
        end
      end

      # Match if the name is matched one of elements.
      #
      # @param name [String]
      #   data name
      # @return [MatchedData,nil]
      #   the matchde data, or nil
      def match(name)
        @elements.each do |element|
          if md = element.match(name)
            return md
          end
        end.tap {return nil}
      end

      # Return true if at least one element accepts nonexistence.
      #
      # @return [Boolean]
      #   true if at least one element accepts nonexistence
      def accept_nonexistence?
        @elements.any?{|element| element.accept_nonexistence?}
      end

      # Evaluate the data expression.
      #
      # @param vtable [VariableTable]
      #   variable table for evaluation
      # @return [BasicModel]
      #   evaluation result
      def eval(vtable)
        self.class.new(*@elements.map {|elt| elt.eval(vtable)})
      end

      def textize
        "data_expr_or(%s)" % @elements.map{|elt| elt.textize}.join(", ")
      end

      # @api private
      def to_s
        "#<#<#{self.class.name}> #{@elements}>"
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        (@elements - other.elements).empty?
      end
      alias :eql? :"=="

      # @api private
      def hash
        @elements.hash
      end

      private

      def find_not_null_element
        @elements.find{|elt| not(elt.kind_of?(DataExprNull))}
      end
    end

    TypeDataExpr.instance_eval do
      define_pione_method("==", [TypeDataExpr], TypeBoolean) do |rec, other|
        PioneBoolean.new(rec == other)
      end

      define_pione_method("!=", [TypeDataExpr], TypeBoolean) do |rec, other|
        PioneBoolean.not(rec.call_pione_method("==", other))
      end

      define_pione_method("all", [], TypeDataExpr) do |rec|
        rec.all
      end

      define_pione_method("each", [], TypeDataExpr) do |rec|
        rec.each
      end

      define_pione_method("except", [TypeDataExpr], TypeDataExpr) do |rec, target|
        rec.except(target)
      end

      define_pione_method("stdout", [], TypeDataExpr) do |rec|
        rec.stdout
      end

      define_pione_method("stderr", [], TypeDataExpr) do |rec|
        rec.stderr
      end

      define_pione_method("neglect", [], TypeDataExpr) do |rec|
        rec.neglect
      end

      define_pione_method("care", [], TypeDataExpr) do |rec|
        rec.care
      end

      define_pione_method("or", [TypeDataExpr], TypeDataExpr) do |rec, other|
        DataExprOr.new(rec, other)
      end

      define_pione_method("join", [TypeString], TypeString) do |rec, connective|
        PioneString.new(rec.elements.map{|elt| elt.name}.join(connective.to_ruby))
      end

      define_pione_method("match?", [TypeString], TypeBoolean) do |rec, name|
        if rec.match(name.value)
          PioneBoolean.true
        else
          PioneBoolean.false
        end
      end

      define_pione_method("as_string", [], TypeString) do |rec|
        case rec
        when DataExprNull
          PioneString.new("")
        when DataExprOr
          PioneString.new(rec.elements.map{|elt| elt.name}.join(DataExpr::SEPARATOR))
        when DataExpr
          PioneString.new(rec.name)
        end
      end
    end
  end
end
