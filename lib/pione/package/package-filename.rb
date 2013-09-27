module Pione
  module Package
    class PackageFilenameParser < Parslet::Parser
      root(:filename)

      rule(:filename) { package_name.maybe >> edition.maybe >> tag.maybe >> hash_id.maybe >> ext }

      rule(:package_name) { ((str("(") | str(".") | str("+") | str("@")).absent? >> any).repeat(1).as(:package_name) }
      rule(:edition) { str("(") >> (str(")").absent? >> any).repeat(1).as(:edition) >> str(")") }
      rule(:tag) { str("+") >> ((ext | str("@")).absent? >> any).repeat(1).as(:tag) }
      rule(:hash_id) { str("@") >>  match('[0-9a-fA-F]').repeat(1).as(:hash_id) }
      rule(:ext) { str(".ppg") }
    end

    class PackageFilename < StructX
      member :package_name
      member :edition, default: "origin"
      member :tag
      member :hash_id

      class << self
        def parse(str)
          new(PackageFilenameParser.new.parse(str))
        end
      end

      def to_s
        name = ""
        name << package_name
        name << "(%s)" % edition if edition and edition != "origin"
        name << "+%s" % tag if tag
        name << "@%s" % hash_id if hash_id
        name + ".ppg"
      end
    end
  end
end

