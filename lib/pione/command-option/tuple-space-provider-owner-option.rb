module Pione
  module CommandOption
    class TupleSpaceProviderOwnerOption
      extend OptionInterface
      use_option_module TupleSpaceProviderOption

      # --without-tuple-space-provider
      define_option(
        '--without-tuple-space-provider',
        'process without tuple space provider'
      ) do
        @without_tuple_space_provider = true
      end
    end
  end
end
