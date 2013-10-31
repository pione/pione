module Pione
  module TestHelper
    module InternetConnectivity
      def self.ok?
        `ping -c 3 -W 1 8.8.8.8 >> /dev/null`
        $? == 0
      end
    end
  end
end
