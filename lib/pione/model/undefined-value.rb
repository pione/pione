module Pione
  module Model
    class UndefinedValue < BasicModel
      set_pione_model_type TypeUndefinedValue

      def ==(other)
        return other.kind_of?(UndefinedValue)
      end

      alias :eql? :"=="

      def hash
        0
      end

      #
      # pione model method
      #
      define_pione_method("as_string", [], TypeString) do |rec|
        PioneString.new("undefined")
      end
    end
  end
end
