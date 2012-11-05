module Pione
  module Front
    module TupleSpaceProviderOwner
      # Sets the uri as tuple space provider.
      # @return [void]
      def set_tuple_space_provider(uri)
        Global.set_tuple_space_provider_uri(uri)
        TupleSpaceProvider.instance.tuple_space_server = tuple_space_server
      end
    end
  end
end
