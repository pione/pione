module Pione
  module Global
    # This is IP address of this system. Note that you should select one IP
    # address if system has multiple addresses.
    define_external_item(:my_ip_address) {Util::IPAddress.myself}
  end
end
