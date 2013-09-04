module Pione
  module System
    # DomainInfo is a domain informations for exporting from PIONE world to
    # externals.
    class DomainInfo < StructX
      # Read domin info file from the location.
      def self.read(location)
        location = location + ".domain.dump" if location.directory?
        new(Marshal.load(location.read))
      end

      member :env

      # Write domain info file into the location.
      def write(location)
        location = location + ".domain.dump" if location.directory?
        unless location.exist?
          location.create(Marshal.dump(env.dumpable))
        else
          location.update(Marshal.dump(env.dumpable))
        end
      end
    end
  end
end
