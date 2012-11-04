module Pione
  module Relay
    class RelayClientDB
      def initialize(path)
        raise TypeError.new(path) unless path.kind_of?(Pathname)
        @path = path
        @table = read_database
      end

      def auth(uuid, name, response)
        Digest::SHA512.hexdigest("%s:%s" % [uuid, @table[name]]) == response
      end

      def add(name, password)
        # stretching x 1000
        @table[name] = (1..1000).inject("") {|hash, _|
          Digest::SHA512.hexdigest("%s:%s:%s" % [hash, name, password])
        }
      end

      def delete(name)
        @table.delete(name)
        save
      end

      def names
        @table.keys
      end

      def save
        @path.open("w+", 0600) do |f|
          @table.each do |name, digest|
            f.puts "%s:%s" % [name, digest] if name and digest
          end
        end
      end

      private

      def read_database
        if @path.exist?
          @path.readlines.inject({}) do |tbl, line|
            name, digest = line.chomp.split(":")
            tbl.tap{ tbl.store(name, digest) }
          end
        else
          {}
        end
      end
    end
  end
end

