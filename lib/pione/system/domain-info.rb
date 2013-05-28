module Pione
  module System
    # DomainInfo is a domain informations for exporting from PIONE world to
    # externals.
    class DomainInfo < StructX
      # Read domin info file from the location.
      #
      # @param location [BasicLocation]
      #   the location of domain info file
      # @return [DomainInfo]
      #   domain information object
      def self.read(location)
        location = location + ".domain.dump" if location.directory?
        new(Marshal.load(location.read))
      end

      member :variable_table

      # Write domain info file into the location.
      #
      # @param location [BasicLocation]
      #   the location of domain info file
      # @return [void]
      def write(location)
        location = location + ".domain.dump" if location.directory?
        unless location.exist?
          location.create(Marshal.dump(variable_table))
        else
          location.update(Marshal.dump(variable_table))
        end
      end
    end
  end
end
