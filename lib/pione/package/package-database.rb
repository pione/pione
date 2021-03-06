module Pione
  module Package
    # Package::Database is a repository of package informations and the digest
    # for cache reference. The keys of database are package name, editor, and
    # tag.
    class Database
      class << self
        # Read package database from the string.
        def read(str)
          JSON.load(str).each_with_object(new) do |data, db|
            db.add(DatabaseRecord.new(
                name: data["PackageName"], editor: data["Editor"], tag: data["Tag"],
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
            db = new
            db.save
            Log::SystemLog.info "PIONE created a new package database at %s" % Global.package_database_location.address
            return db
          end
        end
      end

      def initialize
        # make a 3d table
        @table = Hash.new {|h1,k1| h1[k1] = Hash.new {|h2,k2| h2[k2] = Hash.new}}
        @digests = []
      end

      # Add the record.
      def add(record)
        unless record.kind_of?(DatabaseRecord)
          record = DatabaseRecord.new(record)
        end
        @table[record.name][record.editor || "origin"][record.tag] = record
        @digests << record.digest
      end

      # Delete a record by the tuple of name, editor, and tag. Editor is
      # "origin" if it is nil.
      def delete(name, editor, tag)
        @table[name][editor || "origin"][tag] = nil
      end

      # Return record number of the database.
      def count
        @table.inject(0) do |i1, (_, t1)|
          t1.inject(i1) do |i2, (_, t2)|
            t2.inject(i2) {|i3, (_, val)| val ? i3 + 1 : i3}
          end
        end
      end

      # Return true if the digest is included in package database.
      def has_digest?(digest)
        @digests.include?(digest)
      end

      # Find a record by the tuple of name, editor, and tag. Editor is "origin" if it is nil.
      def find(name, editor, tag)
        @table[name][editor || "origin"][tag]
      end

      # Return true if the package exists in database.
      #
      # @param [String] name
      #   package name
      # @param [String] editor
      #   editor name
      # @param [String] tag
      #   tag name
      # @return [Boolean]
      #   true if the package exists in database
      def exist?(name, editor, tag)
        not(find(name, editor, tag).nil?)
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
          t1.each{|_, t2| t2.each{|_, record| list << record if record}}
        end.to_json(*args)
      end
    end

    # DatabaseRecord is a record of package database.
    class DatabaseRecord < StructX
      member :name
      member :editor
      member :tag
      member :location
      member :state
      member :digest

      def to_json(*args)
        data = Hash.new
        data["PackageName"] = name
        data["Editor"] = editor || "origin"
        data["Tag"] = tag
        data["Location"] = location if location
        data["State"] = state if state
        data["Digest"] = digest
        data.to_json(*args)
      end
    end
  end
end
