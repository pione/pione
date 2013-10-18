module Pione
  module Util
    module TaskDigest
      def self.generate(package_id, rule_name, inputs, param_set)
        case inputs.flatten.size
        when 0
          _inputs = ""
        when 1, 2, 3
          _inputs = inputs.flatten.map{|t| t.name}.join(",")
        else
          _inputs = "%s,..." % inputs.flatten[0..2].map{|i| i.name}.join(",")
        end
        _param_set = param_set.filter(["I", "INPUT", "O", "OUTPUT", "*"])
        _param_set = _param_set.map{|k,v| "%s:%s" % [k, v.textize]}.join(",")
        "&%s:%s([%s],{%s})" % [package_id, rule_name, _inputs, _param_set]
      end
    end

    module PackageDigest
      class << self
        # Generate a MD5 digest of the PPG archive.
        def generate(location)
          case Package::PackageTypeClassifier.classify(location)
          when :archive
            generate_from_ppg(location)
          when :directory
            generate_from_directory_package(location)
          else
            nil
          end
        end

        # Generate a MD5 digest of the directory package.
        def generate_from_directory_package(location)
          files = []

          # package files
          package_info = Package::PackageScanner.scan(location)
          files << "pione-package.json"
          files += package_info.filepaths

          # scenario files
          scenario_infos = package_info.scenarios.map do |scenario|
            files << File.join(scenario, "pione-scenario.json")
            files += Package::ScenarioScanner.scan(location + scenario).filepaths.map do |path|
              File.join(scenario, path)
            end
          end

          # make seed string for digest
          seed = files.sort.each_with_object("") do |filepath, string|
            digest = Digest::MD5.file((location + filepath).path).to_s
            string << "%s %s\n" % [filepath, digest]
          end

          return Digest::MD5.hexdigest(seed)
        end

        # Generate a MD5 digest of the PPG archive.
        def generate_from_ppg(location)
          local_location = location.local
          tmp = Temppath.create
          ::Zip::File.open(local_location.path.to_s) do |zip|
            zip.extract(".digest", tmp)
          end
          Location[tmp].read
        end
      end
    end
  end
end
