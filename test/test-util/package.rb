module TestUtil
  module Package
    class << self
      def get(name)
        TEST_PACKAGE_DIR + name
      end
    end
  end
end
