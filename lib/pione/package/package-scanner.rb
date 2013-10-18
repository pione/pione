module Pione
  module Package
    class PackageScanner
      class << self
        def scan(location)
          new(location).scan
        end
      end

      def initialize(location)
        @package_location = location
      end

      # Scan the package location and return package informations.
      def scan
        if @package_location.directory?
          documents = scan_documents(@package_location)
          name, editor, tag, parents = scan_annotations(documents)
          scenarios = scan_scenarios(@package_location)
          bins = scan_bins(@package_location)

          return PackageInfo.new(
            name: name, editor: editor, tag: tag, parents: parents,
            documents: documents, scenarios: scenarios, bins: bins
          )
        else
          # the case for single document package
          name, editor, tag, parents = scan_annotations([@package_location])
          documents = [@package_location.basename]

          return PackageInfo.new(
            name: name, editor: editor, tag: tag, parents: parents,
            documents: documents
          )
        end
      end

      private

      # Scan PIONE documents in this package. This scans each directory
      # excluding scenarios in the location recursively.
      def scan_documents(location)
        location.entries.each_with_object([]) do |entry, paths|
          if entry.file?
            # PIONE document has extension ".pione"
            if /^[^.].+.pione$/.match(entry.basename)
              # document path should be relative
              paths << entry.path.relative_path_from(@package_location.path).to_s
            end
          else
            # excepting dot-headed or scenario, scan the directory recursively
            unless /^\./.match(entry.basename) or ScenarioScanner.scenario?(entry)
              paths.concat(scan_documents(entry))
            end
          end
        end
      end

      # Scan annotations from documents.
      def scan_annotations(documents)
        # setup temporary language environment for reading annotations
        env = Lang::Environment.new.setup_new_package("PackageScanner")

        # read documents
        documents.each do |doc|
          location = doc.is_a?(Location::DataLocation) ? doc : @package_location + doc
          Document.load(env, location, nil, nil, nil, doc)
        end

        # get annotations
        annotations = env.package_get(Lang::PackageExpr.new(package_id: env.current_package_id)).annotations
        name = find_package_info(annotations, "PackageName")
        editor = find_package_info(annotations, "Editor")
        tag = find_package_info(annotations, "Tag")
        parents = find_parents(annotations)

        return name, editor, tag, parents
      end

      # Find package information of the annotation type from annotations.
      def find_package_info(annotations, annotation_type)
        annotations.each do |annotation|
          if annotation.annotation_type == annotation_type
            return annotation.pieces.first.value
          end
        end

        return nil
      end

      # Find parents from annotaions.
      def find_parents(annotations)
        annotations.each_with_object([]) do |annotation, parents|
          if annotation.annotation_type == "Parent"
            annotation.pieces.each do |parent|
              name = parent.name
              editor = parent.editor ? parent.editor.value : nil
              tag = parent.tag ? parent.tag.value : nil
              parents << ParentPackageInfo.new(name: name, editor: editor, tag: tag)
            end
          end
        end
      end

      # Scan scenarios recursively. See ScnarioScanner for details of scenario
      # directory.
      def scan_scenarios(location)
        location.entries.each_with_object([]) do |entry, list|
          if entry.directory?
            if ScenarioScanner.scenario?(entry)
              list << entry.path.relative_path_from(@package_location.path).to_s
            else
              list.concat(scan_scenarios(entry))
            end
          end
        end
      end

      # Scan script files.
      def scan_bins(location)
        if (location + "bin").exist?
          (location + "bin").entries.each_with_object([]) do |entry, list|
            if entry.file?
              list << entry.path.relative_path_from(@package_location.path).to_s
            end
          end
        else
          return []
        end
      end
    end
  end
end
