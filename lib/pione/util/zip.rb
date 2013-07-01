module Pione
  module Util
    module Zip
      class << self
        # Create a zip archive of the location.
        #
        # @param src [DataLocation]
        #   the source directory location
        # @param archive [DataLocation]
        #   the archive location
        def compress(src, archive)
          # src should be a directory
          raise ArgumentError.new(src) unless src.directory?

          # make local path
          _src = src.local
          _archive = Location[Temppath.create]

          # compress
          ::Zip::Archive.open(_archive.path.to_s, ::Zip::CREATE) do |ar|
            _src.rel_entries(rec: true).each do |relpath|
              relpath = relpath.to_s
              location = _src + relpath
              if location.directory?
                ar.add_dir(relpath)
              else
                ar.add_file(relpath, location.path.to_s)
              end
            end
          end

          # upload archive
          _archive.move(archive)
        end

        # Expand the archive into the destination directory.
        #
        # @param archive [DataLocation]
        #    the archive location
        # @param dest [DataLocation]
        #    the destination directory location
        def uncompress(archive, dest)
          _archive = archive.local
          _dest = dest.local
          ::Zip::Archive.open(_archive.path.to_s) do |ar|
            ar.each do |f|
              path = _dest + f.name
              if f.directory?
                path.mkdir
              else
                f.read(8192) {|chunk| path.append(chunk)}
              end
            end
          end
          _dest.move(dest)
        end
      end
    end
  end
end
