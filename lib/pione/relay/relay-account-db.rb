module Pione
  module Relay
    class RelayAccountDB
      extend Forwardable

      Account = Struct.new(:name, :digest)

      def_delegator :@table, "[]"

      def initialize(path)
        raise TypeError.new(path) unless path.kind_of?(Pathname)
        @path = path
        @table = read_database
      end

      def add(realm, name, password)
        # stretching x 1000
        digest = (1..1000).inject("") {|hash, _|
          Digest::SHA512.hexdigest("%s:%s:%s" % [hash, name, password])
        }
        @table[realm] = Account.new(name, digest)
      end

      def delete(realm)
        @table.delete(realm)
        save
      end

      def realms
        @table.keys
      end

      def save
        @path.open("w+", 0600) do |f|
          @table.each do |realm, account|
            f.puts "%s:%s:%s" % [realm, account.name, account.digest] if realm and account
          end
        end
      end

      private

      def read_database
        if @path.exist?
          @path.readlines.inject({}) do |tbl, line|
            realm, name, digest = line.chomp.split(":")
            tbl.tap{ tbl.store(realm, Account.new(name, digest)) }
          end
        else
          {}
        end
      end
    end
  end
end
