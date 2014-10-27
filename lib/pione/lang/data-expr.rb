module Pione
  module Lang
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
      def compile(pattern)
        s = "^#{Regexp.escape(pattern)}$"
        TABLE.keys.each {|key| s.gsub!(key, TABLE)}
        s.gsub!(/\\\[(!|\\\^)?(.*)\\\]/){"[#{'^' if $1}#{$2.gsub('\-','-')}]"}
        s.gsub!(/\\{(.*)\\}/){"(#{$1.split(',').join('|')})"}
        Regexp.new(s)
      end
      module_function :compile
    end

    # DataExpr is a class for data name expressions of rule input and output.
    class DataExpr < Piece
      piece_type_name "DataExpr"

      member :pattern
      member :exceptions, default: lambda {DataExprSequence.new}
      member :matched_data
      member :location

      # Evaluate exceptions and expand embeded expressions of data pattern.
      def eval(env)
        new_pattern = Util::EmbededExprExpander.expand(env, pattern)
        new_exceptions = exceptions.eval(env)
        set(pattern: new_pattern, exceptions: new_exceptions)
      end

      # Return matched data if the name is matched with the expression.
      def match(name)
        # check exceptions
        return nil if exceptions.match?(name)

        # match test
        return DataExprCompiler.compile(pattern).match(name)
      end

      # Return if the expression accepts nonexistence of corresponding data.
      #
      # @return [Boolean]
      #   false because data expression needs corresponding data
      def accept_nonexistence?
        false
      end

      # Same as Regexp#=~ but return 0 if it matched.
      def =~(other)
        match(other) ? 0 : nil
      end

      # Pattern match.
      def ===(other)
        match(other) ? true : false
      end
    end

    # DataExprNull is a data exppresion that accepts data nonexistence.
    class DataExprNull < DataExpr
      def match(name)
        nil
      end

      def accept_nonexistence?
        true
      end

      # Evaluate the data expression. The result is myself.
      def eval(env)
        self
      end
    end

    class DataExprSequence < OrdinalSequence
      set_pione_type TypeDataExpr
      piece_class DataExpr

      member :output_mode, :default => :file, :values => [:file, :stdout, :stderr]
      member :update_criteria, :default => :care, :values => [:care, :neglect]
      member :operation, :default => :write, :values => [:write, :remove, :touch]
      member :location

      # Return true if the sequence accepts null.
      def accept_nonexistence?
        pieces.any?{|piece| piece.accept_nonexistence?}
      end

      # Return true if the sequence has no null.
      def assertive?
        not(pieces.all?{|piece| piece.kind_of? DataExprNull})
      end

      # Match if the name is matched one of elements.
      def match(name)
        pieces.inject(nil) {|res, piece| res ? res : piece.match(name)}
      end
      alias :"===" :match

      # Return true if the name matched.
      def match?(name)
        match(name) ? true : false
      end
      # This alias is for RINDA's template matcher.
      alias :"=~" :match?

      def textize
        "(<d>%s)" % pieces.map {|piece| "'%s'" % piece.pattern}.join("|")
      end
    end

    TypeDataExpr.instance_eval do
      define_pione_method("[]", [TypeInteger], TypeString) do |env, rec, index|
       StringSequence.map2(rec, index) do |rec_piece, index_piece|
          rec_piece.matched_data[index_piece.value]
        end
      end

      define_pione_method("file", [], TypeDataExpr) do |env, rec|
        rec.set(output_mode: :file)
      end

      define_pione_method("file?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.output_mode == :file)
      end

      define_pione_method("stdout", [], TypeDataExpr) do |env, rec|
        rec.set(output_mode: :stdout)
      end

      define_pione_method("stdout?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.output_mode == :stdout)
      end

      define_pione_method("stderr", [], TypeDataExpr) do |env, rec|
        rec.set(output_mode: :stderr)
      end

      define_pione_method("stderr?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.output_mode == :stderr)
      end

      define_pione_method("neglect", [], TypeDataExpr) do |env, rec|
        rec.set(update_criteria: :neglect)
      end

      define_pione_method("neglect?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.update_criteria == :neglect)
      end

      define_pione_method("care", [], TypeDataExpr) do |env, rec|
        rec.set(update_criteria: :care)
      end

      define_pione_method("care?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.update_criteria == :care)
      end

      define_pione_method("write", [], TypeDataExpr) do |env, rec|
        rec.set(operation: :write)
      end

      define_pione_method("write?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.operation == :write)
      end

      define_pione_method("remove", [], TypeDataExpr) do |env, rec|
        rec.set(operation: :remove)
      end

      define_pione_method("remove?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.operation == :remove)
      end

      define_pione_method("touch", [], TypeDataExpr) do |env, rec|
        rec.set(operation: :touch)
      end

      define_pione_method("touch?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.operation == :touch)
      end

      define_pione_method("except", [TypeDataExpr], TypeDataExpr) do |env, rec, target|
        rec.map {|piece| piece.set(exceptions: piece.exceptions + target)}
      end

      define_pione_method("exceptions", [], TypeDataExpr) do |env, rec|
        rec.fold(DataExprSequence.new) do |seq, piece|
          seq + piece.exceptions
        end
      end

      # Same as +#|+. Data expression sequence represents or-relations.
      define_pione_method("or", [TypeDataExpr], TypeDataExpr) do |env, rec, other|
        rec.call_pione_method(env, "|", [other])
      end

      # Return names which the receiver matches.
      define_pione_method("match", [TypeString], TypeString) do |env, rec, name|
        rec.fold2(StringSequence.new, name) do |seq, rec_piece, name_piece|
          if md = rec_piece.match(name_piece.value)
            md.to_a.inject(seq) do |_seq, matched|
              seq.push(PioneString.new(matched))
            end
          else
            seq
          end
        end
      end

      # Return true if the recevier match the name.
      define_pione_method("match?", [TypeString], TypeBoolean) do |env, rec, name|
        BooleanSequence.map2(rec, name) do |rec_piece, name_piece|
          not(rec_piece.match(name_piece.value).nil?)
        end
      end

      # Convert the data expression into a string. null data expression converts into empty string.
      define_pione_method("as_string", [], TypeString) do |env, rec|
        StringSequence.map(rec) do |piece|
          case piece
          when DataExprNull
            ""
          when DataExpr
            piece.pattern
          end
        end
      end

      define_pione_method("accept_nonexistence?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.accept_nonexistence?)
      end

      define_pione_method("suffix", [TypeDataExpr], TypeDataExpr) do |env, rec, new_suffix|
        rec.call_pione_method(env, "suffix", [new_suffix.call_pione_method(env, "as_string", [])])
      end

      define_pione_method("suffix", [TypeString], TypeDataExpr) do |env, rec, new_suffix|
        rec.map2(new_suffix) do |rec_piece, new_suffix_piece|
          case rec_piece
          when DataExprNull
            rec_piece
          when DataExpr
            basename = File.basename(rec_piece.pattern, ".*")
            rec_piece.set(pattern: "%s.%s" % [basename, new_suffix_piece.value])
          end
        end
      end

      define_pione_method("join", [TypeString], TypeString) do |env, rec, sep|
        rec.call_pione_method(env, "str", []).call_pione_method(env, "join", [sep])
      end

      define_pione_method("join", [], TypeString) do |env, rec, sep|
        rec.call_pione_method(env, "str", []).call_pione_method(env, "join", [])
      end
    end
  end
end
