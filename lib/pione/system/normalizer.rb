module Pione
  module System
    # `Normalizer` is a utility module that normalizes values into normalization
    # types. If values cannot normalize, this method raises
    # `NormalizerValueError`. Normalization types are followings:
    module Normalizer
      class << self
        def location(val)
          if val.kind_of?(Location::BasicLocation)
            val
          else
            Location[val]
          end
        rescue => e
          raise NormalizerValueError.new(:location, val, e.message)
        end

        def param_set(val)
          p val
          Util.parse_param_set(val)
        end

        def nortification_address(val)
          Notification::Address.target_address_to_uri(address.strip)
          unless ["pnb", "pnm", "pnu"].include?(uri.scheme)

          end
        end
      end
    end
  end
end

Rootage::Normalizer.set(:location) do |val|
  Pione::System::Normalizer.location(val)
end

Rootage::Normalizer.set(:param_set) do |val|
  Pione::System::Normalizer.param_set(val)
end
