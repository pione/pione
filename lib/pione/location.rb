module Pione
  # Location is a name space for all location classes.
  module Location; end
end

require 'pione/location/exception.rb'
require 'pione/location/basic-location'
require 'pione/location/data-location'
require 'pione/location/local-location'
require 'pione/location/ftp-location'
require 'pione/location/http-location'
require 'pione/location/https-location'
require 'pione/location/dropbox-location'
require 'pione/location/git-repository-location'

