module Pione
  module TestHelper
    module Location
      # Test location scheme.
      def self.test_scheme(path)
        dir = File.dirname(path)
        name = File.basename(path, ".rb").sub("spec_", "")
        yml_path = File.join(dir, 'data', '%s.yml' % name)

        describe "location scheme test" do
          YAML.load_file(yml_path).each do |testcase|
            if uri = testcase.keys.first
              testcase[uri].keys.each do |name|
                # expectation
                expectation = testcase[uri][name]
                expectation = nil if expectation == "nil"

                # test
                URI.parse(uri).__send__(name).should == expectation
              end
            end
          end
        end
      end
    end
  end
end
