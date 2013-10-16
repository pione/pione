module Pione
  module Package
    class PackageFilenameParser < Parslet::Parser
      root(:filename)

      rule(:filename) { package_name.maybe >> edition.maybe >> tag.maybe >> digest.maybe >> ext.maybe }

      rule(:package_name) { ((str("(") | str(".") | str("+") | str("@")).absent? >> any).repeat(1).as(:package_name) }
      rule(:edition) { str("(") >> (str(")").absent? >> any).repeat(1).as(:edition) >> str(")") }
      rule(:tag) { str("+") >> ((ext | str("@")).absent? >> any).repeat(1).as(:tag) }
      rule(:digest) { str("@") >>  match('[0-9a-fA-F]').repeat(1).as(:digest) }
      rule(:ext) { str(".ppg") }
    end

    class PackageFilename < StructX
      member :package_name
      member :edition, default: "origin"
      member :tag
      member :digest

      class << self
        # Parse the filename.
        def parse(str)
          begin
            new(PackageFilenameParser.new.parse(str))
          rescue => e
            raise InvalidPackageFilename.new(str, e)
          end
        end
      end

      def string(ext=true)
        name = ""
        name << package_name
        name << "(%s)" % edition if edition and edition != "origin"
        name << "+%s" % tag if tag
        name << "@%s" % digest if digest
        name << ".ppg" if ext
        return name
      end

      alias :to_s :string
    end
  end
end

