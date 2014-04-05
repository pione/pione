module Pione
  # Location is a name space for all location classes.
  module Location; end
end

require 'pione/location/location-exception.rb'

# URI schemes
require 'pione/location/location-scheme'
require 'pione/location/local-scheme'
require 'pione/location/dropbox-scheme'
require 'pione/location/broadcast-scheme'
require 'pione/location/myftp-scheme'
require 'pione/location/notification-scheme'

# storage
require 'pione/location/basic-location'
require 'pione/location/data-location'
require 'pione/location/local-location'
require 'pione/location/ftp-location'
require 'pione/location/http-location'
require 'pione/location/https-location'
require 'pione/location/dropbox-location'

# others
require 'pione/location/git-repository-location'


