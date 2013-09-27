module Pione
  module Package
    # PackageExpander expands package files from archive.
    class PackageExpander
      attr_reader :location

      # @param location [BasicLoaction]
      #   package location
      def initialize(location)
        @location = location
      end

      def expand(output)
        location = @location.local

        # expand
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
