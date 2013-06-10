module Pione
  module Option
    # TupleSpaceProviderOption provides options for commands that make tuple
    # space provider agent.
    module TupleSpaceProviderOwnerOption
      extend OptionInterface

      define(:without_tuple_space_provider) do |item|
        item.long = '--without-tuple-space-provider'
        item.desc = 'process without tuple space provider'
        item.value = true
      end
    end
  end
end
