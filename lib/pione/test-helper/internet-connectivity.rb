module Pione
  module TestHelper
    module InternetConnectivity
      def self.ok?
        `ping -c 5 www.google.com > /dev/null`
        $? == 0
      end
    end
  end
end
