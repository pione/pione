module Pione
  module Model
    # DataExpr::Compiler is a regexp compiler for data expression.
    module DataExprCompiler
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


    # DataExpr is a class for data name expressions of rule input and output.
    #
    # @example
    #   # complete name
    #   DataExpr.new("test.txt")
    # @example
    #   # incomplete name
    #   DataExpr.new("*.txt")
    class DataExpr < Element
      class << self
        # Create a named expression.
        #
        # @param name [String]
        #   data name
        def [](name)
          new(name)
        end

        # Return convertion prcedure for enumerable.
        #
        # @return [Proc]
        #   +Proc+ object that returns data expression with name
        def to_proc
          Proc.new{|name| name.kind_of?(self) ? name : self.new(name)}
        end
      end

      attr_reader :name
      alias :core :name
      forward_as_key! :@data, :exceptions, :matched_data, :location

      # Create a data expression.
      #
      # @param name [String]
      #   data expression name
      # @param opts [Hash]
      #   options of the expression
      # @option opts [Array<DataExpr>] :exceptions
      #   exceptional expressions
      # @option opts [String] :match
      def initialize(name, data={})
        @name = name
        @data = Hash.new
        @data[:exceptions] = data[:exceptions] || []
        @data[:matched_data] = data[:matched_data] || []
        @data[:location] = data[:location] || nil
      end

      def set_name(name)
        self.class.new(name, @data)
      end

      def set_data(data)
        self.class.new(@name, @data.merge(data))
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
      def textize
        "data_expr(\"#{name}\", [%s])" % [
          exceptions.map{|exc| exc.textize}.join(",")
        ]
      end

      # Create new data expression with appending the exception.
      #
      # @param exc [DataExpr, String]
      #   data name for exceptions
      # @return [DataExpr]
      #   new data name with the exception
      def except(exc)
        new_exceptions = exceptions + [exc.kind_of?(DataExpr) ? exc : DataExpr.new(exc)]
        return self.class.new(core, @data.merge(exceptions: new_exceptions))
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

      # @api private
      def to_s
        "#<DataExpr '%s' %s>" % [name, @data.inspect]
      end

      # Return true if name, distribution, mode, and exceptions are the same.
      #
      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        return false unless name == other.name
        return false unless exceptions.sort == other.exceptions.sort
        return true
      end
      alias :eql? :"=="

      # @api private
      def hash
        [name, exceptions].join("\000").hash
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
        DataExprCompiler.compile(name)
      end

      # Return true if the name matchs exceptions.
      #
      # @api private
      def match_exceptions(name)
        not(exceptions.select{|ex| ex.match(name)}.empty?)
      end
    end

    # DataExprNull is a data exppresion that accepts data nonexistence.
    class DataExprNull < DataExpr
      include Singleton

      # null returns itself for property change methods
      def return_self
        self
      end

      alias :all :return_self
      alias :each :return_self
      alias :stdout :return_self
      alias :stderr :return_self
      alias :neglect :return_self
      alias :care :return_self
      alias :write :return_self
      alias :remove :return_self
      alias :touch :return_self

      def initialize
        @data = {}
      end

      def match(name)
        nil
      end

      def accept_nonexistence?
        true
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
        "#<DataExprNull>"
      end

      # @api private
      def ==(other)
        self.class == other.class
      end
      alias :eql? :"=="
    end

    class DataExprSequence < OrdinalSequence
      set_pione_model_type TypeDataExpr
      set_element_class DataExpr
      set_shortname "DSeq"
      DataExpr.set_sequence_class self
      DataExprNull.set_sequence_class self

      define_sequence_attribute :output_mode, :file, :stdout, :stderr
      define_sequence_attribute :update_criteria, :care, :neglect
      define_sequence_attribute :operation, :write, :remove, :touch
      define_sequence_attribute :location, nil
      define_sequence_attribute :exceptions, []

      forward! Proc.new{@elements.first}, :match, :name

      def accept_nonexistence?
        @elements.any?{|elt| elt.accept_nonexistence?}
      end

      def assertive?
        not(@elements.all?{|elt| elt.kind_of? DataExprNull})
      end

      # Match if the name is matched one of elements.
      #
      # @param name [String]
      #   data name
      # @return [MatchedData,nil]
      #   the matchde data, or nil
      def match(name)
        # check exceptions
        return nil if match_exceptions(name)

        # check to match the expression
        @elements.each do |element|
          if md = element.match(name)
            return md
          end
        end

        # failed to match
        return nil
      end

      def match?(name)
        not(match(name).nil?)
      end
      alias :"=~" :match?

      # Return true if the name matchs exceptions.
      def match_exceptions(name)
        not(exceptions.select{|ex| ex.match(name)}.empty?)
      end
    end

    TypeDataExpr.instance_eval do
      define_pione_method("==", [TypeDataExpr], TypeBoolean) do |vtable, rec, other|
        PioneBoolean.new(rec == other).to_seq
      end

      define_pione_method("[]", [TypeInteger], TypeString) do |vtable, rec, index|
        sequential_map2(TypeString, rec, index) do |rec_elt, index_elt|
          rec_elt.matched_data[index_elt.value]
        end.set_separator(DataExpr::SEPARATOR)
      end

      define_pione_method("all", [], TypeDataExpr) do |vtable, rec|
        rec.set_all
      end

      define_pione_method("all?", [], TypeBoolean) do |vtable, rec|
        rec.all?
      end

      define_pione_method("each", [], TypeDataExpr) do |vtable, rec|
        rec.set_each
      end

      define_pione_method("each?", [], TypeBoolean) do |vtable, rec|
        rec.each?
      end

      define_pione_method("stdout", [], TypeDataExpr) do |vtable, rec|
        rec.set_stdout
      end

      define_pione_method("stdout?", [], TypeBoolean) do |vtable, rec|
        rec.stdout?
      end

      define_pione_method("stderr", [], TypeDataExpr) do |vtable, rec|
        rec.set_stderr
      end

      define_pione_method("stderr?", [], TypeBoolean) do |vtable, rec|
        rec.stderr?
      end

      define_pione_method("neglect", [], TypeDataExpr) do |vtable, rec|
        rec.set_neglect
      end

      define_pione_method("neglect?", [], TypeBoolean) do |vtable, rec|
        rec.neglect?
      end

      define_pione_method("care", [], TypeDataExpr) do |vtable, rec|
        rec.set_care
      end

      define_pione_method("care?", [], TypeBoolean) do |vtable, rec|
        rec.care?
      end

      define_pione_method("write", [], TypeDataExpr) do |vtable, rec|
        rec.set_write
      end

      define_pione_method("write?", [], TypeBoolean) do |vtable, rec|
        rec.write?
      end

      define_pione_method("remove", [], TypeDataExpr) do |vtable, rec|
        rec.set_remove
      end

      define_pione_method("remove?", [], TypeBoolean) do |vtable, rec|
        rec.remove?
      end

      define_pione_method("touch", [], TypeDataExpr) do |vtable, rec|
        rec.set_touch
      end

      define_pione_method("touch?", [], TypeBoolean) do |vtable, rec|
        rec.touch?
      end

      define_pione_method("except", [TypeDataExpr], TypeDataExpr) do |vtable, rec, target|
        map2(rec, target) do |rec_elt, target_elt|
          rec_elt.except(target_elt)
        end
      end

      define_pione_method("exceptions", [], TypeDataExpr) do |vtable, rec|
        rec.elements.map do |elt|
          elt.exceptions
        end.flatten.tap{|x| break DataExprSequence.new(x)}
      end

      define_pione_method("or", [TypeDataExpr], TypeDataExpr) do |vtable, rec, other|
        rec.call_pione_method(vtable, "|", other)
      end

      # Return names which the receiver matches.
      define_pione_method("match", [TypeString], TypeString) do |vtable, rec, name|
        rec.match(name.value).to_a.inject(StringSequence.empty) do |seq, matched|
          seq.push(PioneString.new(matched))
        end
      end

      # Return true if the recevier match the name.
      define_pione_method("match?", [TypeString], TypeBoolean) do |vtable, rec, name|
        sequential_map2(TypeBoolean, rec, name) do |rec_elt, name_elt|
          not(rec_elt.match(name_elt.value).nil?)
        end
      end

      define_pione_method("as_string", [], TypeString) do |vtable, rec|
        sequential_map1(TypeString, rec) do |rec_elt|
          case rec_elt
          when DataExprNull
            ""
          when DataExpr
            rec_elt.name
          end
        end
      end

      define_pione_method("accept_nonexistence?", [], TypeBoolean) do |vtable, rec|
        BooleanSequence.of(rec.accept_nonexistence?)
      end

      define_pione_method("suffix", [TypeString], TypeDataExpr) do |vtable, rec, new_suffix|
        TypeDataExpr.map1(rec) do |elt|
          case elt
          when DataExprNull
            elt
          when DataExpr
            basename = File.basename(elt.name, ".*")
            elt.set_name("%s.%s" % [basename, new_suffix.value])
          end
        end
      end
    end
  end
end
