module Pione
  module Option
    # TupleSpaceProviderOption provides options for commands that make tuple
    # space provider agent.
    module TupleSpaceProviderOwnerOption
      extend OptionInterface
      use TupleSpaceProviderOption

      # --without-tuple-space-provider
      option(
        '--without-tuple-space-provider',
        'process without tuple space provider'
      ) do |data|
        data[:without_tuple_space_provider] = true
      end
    end
  end
end
