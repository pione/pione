module Pione
  module Model
    # PioneBoolean representes truth value in PIONE system.
    class PioneBoolean < BasicModel
      set_pione_model_type TypeBoolean

      # Returns the value in ruby.
      attr_reader :value

      class << self
        # Return true value in PIONE system.
        #
        # @return [PioneBoolean]
        #   true value
        def true
          new(true)
        end

        # Return false value in PIONE system.
        #
        # @return [PioneBoolean]
        #   false value
        def false
          new(false)
        end

        # Return inverse value of it.
        #
        # @param boolean [Boolean]
        #   target value
        # @return [PioneBoolean]
        #   true if the param is false, or false
        def not(boolean)
          new(not(boolean.value))
        end

        # Return true value if arguments include true value.
        #
        # @param args [Array<PioneBoolean>]
        # @return [PioneBoolean]
        #   true value if arguments include true value
        def or(*args)
          new(args.any?{|arg| arg.true?})
        end

        # Return true value if all arguments has true value.
        #
        # @param args [Array<PioneBoolean>]
        # @return [PioneBoolean]
        #   true value if all arguments has true value
        def and(*args)
          new(args.all?{|arg| arg.true?})
        end
      end

      # Create a value.
      #
      # @param value [Boolean]
      #   true or false
      def initialize(value)
        @value = value
        super()
      end

      # @api private
      def task_id_string
        "Boolean<#{@value}>"
      end

      # @api private
      def textize
        @value.to_s
      end

      # Return true if the value is true.
      #
      # @return [Boolean]
      #   true if the value is true
      def true?
        @value == true
      end

      # Return true if the value is false.
      #
      # @return [Boolean]
      #   true if the value is false
      def false?
        @value == false
      end

      # Return ruby's boolean value.
      #
      # @return [Boolean]
      #   ruby's boolean value
      def to_ruby
        return @value
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        @value == other.value
      end

      alias :eql? :"=="

      # @api private
      def hash
        @value.hash
      end

      #
      # pione methods
      #

      define_pione_method("==", [TypeBoolean], TypeBoolean) do |rec, other|
        PioneBoolean.new(rec.value == other.value)
      end

      define_pione_method("!=", [TypeBoolean], TypeBoolean) do |rec, other|
        PioneBoolean.not(rec.call_pione_method("==", other))
      end

      define_pione_method("&&", [TypeBoolean], TypeBoolean) do |rec, other|
        PioneBoolean.new(rec.value && other.value)
      end

      define_pione_method("||", [TypeBoolean], TypeBoolean) do |rec, other|
        PioneBoolean.new(rec.value || other.value)
      end

      define_pione_method("and", [TypeBoolean], TypeBoolean) do |rec, other|
        rec.call_pione_method("&&", other)
      end

      define_pione_method("or", [TypeBoolean], TypeBoolean) do |rec, other|
        rec.call_pione_method("||", other)
      end

      define_pione_method("as_string", [], TypeString) do |rec|
        PioneString.new(rec.value.to_s)
      end

      define_pione_method("not", [], TypeBoolean) do |rec|
        PioneBoolean.not(rec)
      end
    end
  end
end
