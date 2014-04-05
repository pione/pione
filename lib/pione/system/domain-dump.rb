module Pione
  module System
    # `DomainDump` is a class that dumps domain environment as a file for
    # exporting the environment from PIONE world to externals.
    class DomainDump < StructX
      FILENAME = ".domain.dump"

      # Load the domain dump file.
      #
      # @param location [Location::DataLocation]
      #   the domain dump file
      # @return [DomainDump]
      #   domain dump object
      def self.load(location)
        if location.directory?
          location = location + FILENAME
        end

        new(Marshal.load(location.read))
      end

      member :env

      # Write a domain dump file.
      def write(location)
        if location.directory?
          location = location + ".domain.dump"
        end

        location.write(Marshal.dump(env.dumpable))
      end
    end
  end
end
