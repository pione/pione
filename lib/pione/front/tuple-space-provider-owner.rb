module Pione
  module Front
    module TupleSpaceProviderOwner
      # Sets the uri as tuple space provider.
      # @return [void]
      def set_tuple_space_provider(uri)
        Global.tuple_space_provider_uri = uri
      end
    end
  end
end
