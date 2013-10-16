module Pione
  module Package
    # PackageInfo is a information storage about package.
    class PackageInfo < StructX
      member :name
      member :editor
      member :tag
      member :parents, default: lambda { Array.new }
      member :documents, default: lambda { Array.new }
      member :scenarios, default: lambda { Array.new }
      member :bins, default: lambda { Array.new }

      # Read package information from the string.
      def self.read(str)
        data = JSON.load(str)
        args = Hash.new
        args[:name] = data["PackageName"] if data.has_key?("PackageName")
        args[:editor] = data["Editor"] if data.has_key?("Editor")
        args[:tag] = data["Tag"] if data.has_key?("Tag")
        args[:parents] = data["Parents"].map {|_data| ParentPackageInfo.json_create(_data)}
        args[:documents] = data["Documents"]
        args[:scenarios] = data["Scenarios"]
        args[:bins] = data["Bins"]
        new(args)
      end

      # Convert to JSON object.
      def to_json(*args)
        data = {}
        data["PackageName"] = name
        data["Editor"] = editor if editor
        data["Tag"] = tag if tag
        data["Parents"] = parents
        data["Documents"] = documents
        data["Scenarios"] = scenarios
        data["Bins"] = bins
        data.to_json(*args)
      end
    end

    # ParentPackageInfo is a information set about parent package.
    class ParentPackageInfo < StructX
      member :name
      member :editor
      member :tag

      def self.json_create(data)
        args = Hash.new
        args[:name] = data["PackageName"]
        args[:editor] = data["Editor"] if data.has_key?("Editor")
        args[:tag] = data["Tag"] if data.has_key?("Tag")
        new(args)
      end

      def to_json
        data = {}
        data["PackageName"] = name
        data["Editor"] = editor if editor
        data["Tag"] = tag if tag
        data.to_json
      end
    end
  end
end
