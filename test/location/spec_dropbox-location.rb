require 'pione/test-helper'
require_relative 'location-behavior'

#
# If you want to enable this test, you should set environment variable
# "DROPBOX_LOCATION_TEST".
#
#     % DROPBOX_LOCATION_TEST=true bundle exec rake test
#
if ENV["DROPBOX_LOCATION_TEST"] == "true"
  describe Pione::Location::DropboxLocation do
    if Location::DropboxLocation.cached? and TestHelper::InternetConnectivity.ok?
      before do
        tuple_space = TupleSpace::TupleSpaceServer.new
        Location::DropboxLocation.setup_for_cui_client(tuple_space)

        path = Location["dropbox:/spec_dropbox-location/"] + Util::UUID.generate
        @file = path + Util::UUID.generate
        @dir = path
        (@dir + "A").create("A")
        (@dir + "B").create("B")
        (@dir + "C").create("C")
        (@dir + "D" + "X").create("X")
        (@dir + "D" + "Y").create("Y")
        (@dir + "D" + "Z").create("Z")
      end

      after do
        @file.delete
        @dir.delete
      end

      behaves_like "location"
    else
      puts "*** Ignored the test because the cache of Dropbox's access token doesn't exist. ***"
      puts "*** Run pione-client with Dropbox location once if you want run this test.      ***"
    end
  end
end
