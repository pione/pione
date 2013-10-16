module Pione
  module Package
    # Package::Database is a repository of package informations and the digest
    # for cache reference. The keys of database are package name, edition, and
    # tag.
    class Database
      class << self
        # Read package database from the string.
        def read(str)
          JSON.load(str).each_with_object(new) do |data, db|
            db.add(DatabaseRecord.new(
                name: data["PackageName"], edition: data["Edition"], tag: data["Tag"],
                location: data["Location"], state: data["State"], digest: data["Digest"]
            ))
          end
        end

        # Load package database from the location. The location should be local.
        def load(location=Global.package_database_location)
          unless location.local?
            raise DatabaseError.new("package database file should be in local: %s" % location.address)
          end

          if location.exist?
            read location.path.open(File::RDONLY) do |f|
              f.flock(File::LOCK_SH)
              f.read
            end
          else
            new
            # raise DatabaseError.new("package database file not found: %s" % Global.package_database_location.address)
          end
        end
      end

      def initialize
        # make a 3d table
        @table = Hash.new {|h1,k1| h1[k1] = Hash.new {|h2,k2| h2[k2] = Hash.new}}
      end

      # Add the record.
      def add(record)
        unless record.kind_of?(DatabaseRecord)
          record = DatabaseRecord.new(record)
        end
        @table[record.name][record.edition || "origin"][record.tag] = record
      end

      # Delete a record by the tuple of name, edition, and tag. Edition is
      # "origin" if it is nil.
      def delete(name, edition, tag)
        @table[name][edition || "origin"][tag] = nil
      end

      # Return record number of the database.
      def count
        @table.inject(0) do |i1, (_, t1)|
          t1.inject(i1) do |i2, (_, t2)|
            t2.inject(i2) {|i3, (_, val)| val ? i3 + 1 : i3}
          end
        end
      end

      # Find a record by the tuple of name, edition, and tag. Edition is "origin" if it is nil.
      def find(name, edition, tag)
        @table[name][edition || "origin"][tag]
      end

      # Save the database to the location.
      def save(location=Global.package_database_location)
        json = JSON.generate(self)

        # NOTE: File#flock needs read & write mode to avoid truncating without lock
        location.path.open(File::RDWR|File::CREAT) do |f|
          f.flock(File::LOCK_EX)
          f.rewind
          f.write(json)
          f.flush
          f.truncate(f.pos)
        end
      end

      # Convert to JSON.
      def to_json(*args)
        @table.each_with_object([]) do |(_, t1), list|
          t1.each{|_, t2| t2.each{|_, record| list << record}}
        end.to_json(*args)
      end
    end

    # DatabaseRecord is a record of package database.
    class DatabaseRecord < StructX
      member :name
      member :edition
      member :tag
      member :location
      member :state
      member :digest

      def to_json(*args)
        data = Hash.new
        data["PackageName"] = name
        data["Edition"] = edition
        data["Tag"] = tag
        data["Location"] = location if location
        data["State"] = state if state
        data["Digest"] = digest
        data.to_json(*args)
      end
    end
  end
end
