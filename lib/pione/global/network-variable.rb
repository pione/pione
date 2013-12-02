module Pione
  module Global
    # This is IP address of this system. Note that you should select one IP
    # address if system has multiple addresses.
    define_external_item(:communication_address) do |item|
      item.desc = "IP address for interprocess communication"
      item.init = Util::IPAddress.myself
    end
  end
end
