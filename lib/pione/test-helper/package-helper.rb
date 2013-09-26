module Pione
  module TestHelper
    module Package
      class << self
        def get(name)
          Pione::Location[File.dirname(__FILE__)] + ".." + ".." + ".." + "test" + "test-data" + "package" + name
        end
      end
    end
  end
end
