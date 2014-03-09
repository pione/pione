module Pione
  module Location
    # LocalLocation represents local disk locations.
    class LocalLocation < DataLocation
      set_scheme "local"
      set_real_appendable true

      def initialize(uri)
        super(uri.absolute)
      end

      def rebuild(path)
        scheme = @uri.scheme
        path = path.expand_path.to_s
        Location["%s:%s" % [scheme, path]]
      end

      def create(data)
        if @path.exist?
          raise ExistAlready.new(self)
        else
          @path.dirname.mkpath unless @path.dirname.exist?
          @path.open("w"){|f| f.write(data)}
        end
        return self
      end

      def append(data)
        if exist?
          @path.open("a"){|f| f.write(data)}
        else
          create(data)
        end
        return self
      end

      def read
        @path.exist? ? @path.read : (raise NotFound.new(self))
      end

      def update(data)
        if @path.exist?
          @path.open("w"){|file| file.write(data)}
        else
          raise NotFound.new(@uri)
        end
      end

      def delete
        if @path.exist?
          if @path.file?
            @path.delete
          else
            FileUtils.remove_entry_secure(@path)
          end
        end
      end

      def mkdir
        @path.mkpath unless exist?
      end

      def ctime
        @path.exist? ? @path.ctime : (raise NotFound.new(self))
      end

      def mtime
        @path.exist? ? @path.mtime : (raise NotFound.new(self))
      end

      def mtime=(time)
        @path.utime(@path.atime, time)
      end

      def size
        @path.exist? ? @path.size : (raise NotFound.new(self))
      end

      def entries(option={rec: false})
        rel_entries(option).map do |entry|
          Location["local:%s" % (@path + entry).expand_path]
        end
      rescue Errno::ENOENT
        raise NotFound.new(self)
      end

      def rel_entries(option={rec: false})
        list = []
        @path.entries.each do |entry|
          if not(entry.to_s == "." or entry.to_s == "..")
            list << entry
            entry_location = self + entry
            if option[:rec] and entry_location.directory?
              _list = entry_location.rel_entries(option).map {|subentry| entry + subentry}
              list = list + _list
            end
          end
        end
        return list
      rescue Errno::ENOENT
        raise NotFound.new(self)
      end

      def each_entry(option={rec: false}, &b)
        each_rel_entry(option) do |entry|
          yield Location["local:%s" % (@path + entry).expand_path]
        end
      rescue Errno::ENOENT
        raise NotFound.new(self)
      end

      def each_rel_entry(option={rec: false}, &b)
        if block_given?
          @path.each_entry do |entry|
            # ignore current or parent directory
            next if entry.to_s == "." or entry.to_s == ".."

            # call the block
            yield entry

            # recursion mode
            entry_location = self + entry
            if option[:rec] and entry_location.directory?
              entry_location.rel_entries(option) do |subentry|
                yield File.join(entry, subentry)
              end
            end
          end
        else
          return Enumerator.new(self, :foreach)
        end
      rescue Errno::ENOENT
        raise NotFound.new(self)
      end

      def file?
        @path.file?
      end

      def directory?
        @path.directory?
      end

      def exist?
        @path.exist?
      end

      def move(dest)
        raise NotFound.new(self) unless exist?

        if dest.kind_of?(LocalLocation)
          dest.path.dirname.mkpath unless dest.path.dirname.exist?
          FileUtils.mv(@path, dest.path, force: true)
        else
          copy(dest)
          delete
        end
      end

      def copy(dest, option={})
        # setup options
        option[:keep_mtime] ||= true

        if dest.kind_of?(LocalLocation)
          # make parent directories
          dest.path.dirname.mkpath unless dest.path.dirname.exist?

          # copy
          IO.copy_stream(@path.open, dest.path)
        else
          dest.write(read)
        end

        # modify mtime
        begin
          dest.mtime = self.mtime if option[:keep_mtime]
        rescue NotImplemented
          msg = "the location operation faild to keep mtime: copy from %s to %s"
          Log::SystemLog.debug(msg % [address, dest.address])
        end
      end

      def link(orig)
        if orig.kind_of?(LocalLocation)
          @path.make_symlink(orig.path)
        else
          orig.copy(self)
        end
      end

      def turn(dest)
        if not(Global.no_file_sliding) and dest.kind_of?(LocalLocation)
          move(dest)
          link(dest)
        else
          copy(dest)
        end
      end
    end
  end
end
