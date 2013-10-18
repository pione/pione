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
          ::Zip::File.open(_archive.path.to_s, ::Zip::File::CREATE) do |zip|
            _src.rel_entries(rec: true).each do |relpath|
              relpath = relpath.to_s
              location = _src + relpath
              if location.directory?
                zip.mkdir(relpath)
              else
                entry = zip.add(relpath, location.path.to_s)
                entry.time = ::Zip::DOSTime.at(location.mtime)
                entry.extra.delete("UniversalTime")
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
          ::Zip::File.open(_archive.path.to_s) do |zip|
            zip.each do |entry|
              if entry.directory?
                (dest + entry.name).mkdir
              else
                tmp = Temppath.create
                entry.extract(tmp)
                Location[tmp].move(dest + entry.name)
              end
            end
          end
        end
      end
    end
  end
end
