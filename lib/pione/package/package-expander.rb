module Pione
  module Package
    # PackageExpander expands package files from ZIP archive.
    class PackageExpander
      attr_reader :location

      # Create a instance with the target location.
      #
      # @param location [BasicLoaction]
      #   package location
      def initialize(location)
        @location = location
      end

      # Expand package files into the output location.
      def expand(output)
        # make local cache of target location
        location = @location.local

        # expand zip archive
        Zip::File.open(location.path.to_s) do |zip|
          zip.each do |entry|
            unless entry.ftype == :directory
              tmp = Temppath.create
              entry.extract(tmp.to_s)
              Location[tmp].move(output + entry.name)
            end
          end
        end
      end

      private

      def valid_filename?
        filename = @location.basename
        if File.extname(filename) == ".ppg"
          identifiers = filename.split("-")
          identifiers[1]
        end
      end
    end
  end
end
