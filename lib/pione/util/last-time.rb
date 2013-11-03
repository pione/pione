module Pione
  module Util
    module LastTime
      # Return last time of data locations. The criteria of last time is
      # location's mtime and ctime.
      def self.get(locations)
        locations.inject(nil) do |last_time, location|
          mtime = location.mtime            # mtime should be supported
          ctime = location.ctime rescue nil # ctime may be not supported

          # get newer time
          this_time = [mtime, ctime].max

          # compare
          (last_time.nil? or last_time < this_time) ? this_time : last_time
        end
      end
    end
  end
end
