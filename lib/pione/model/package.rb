module Pione::Model
  class Package < Pione
    def initialize(name)
      @name = name
    end

    def pione_model_type
      TypePackage
    end

  end
end
