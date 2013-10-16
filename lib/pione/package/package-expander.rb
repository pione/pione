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
        Zip::Archive.open(location.path.to_s) do |ar|
          ar.each do |file|
            unless file.directory?
              (output + file.name).write(file.read)
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
