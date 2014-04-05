module Pione
  module Command
    # PioneClean is a command for clearing temporary files created by PIONE
    # system.
    class PioneClean < BasicCommand
      #
      # basic informations
      #

      define(:name, "pione-clean")
      define(:desc, "Remove PIONE's temporary files, cache, and etc")

      #
      # options
      #

      option CommonOption.debug

      option(:older) do |item|
        item.type = :string
        item.long = '--older'
        item.arg  = 'DATE'
        item.desc = 'remove file older than the date'
      end

      option(:type) do |item|
        item.type = :string
        item.range = ["all", "temporary", "file-cache", "package-cache", "profile"]
        item.long = '--type NAME'
        item.desc = 'remove only files of the type'
        item.init = "all"
      end

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |item|
        item << :older_date
        item << :package_database
      end

      setup(:older_date) do |item|
        item.desc = "Setup older date"

        item.assign(:older) do
          Rootage::Normalizer.normalize(:date, model[:older])
        end

        item.exception do |e|
          begin
            model[:older] = Date.today - model[:older].to_i
          rescue
            cmd.abort("invalid value of older option: %s" % str)
          end
        end
      end

      setup(:package_database) do |item|
        item.desc = "Load pakcage database"

        item.assign(:db) do
          Package::Database.load
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :remove_temporary
        item << :remove_file_cache
        item << :remove_package_cache
        item << :remove_profile
      end

      # This removes working files based on temporary directory's mtime.
      execution(:remove_temporary) do |item|
        item.desc = "Remove temporary files"

        item.process do
          test(type?("temprary"))

          Location[Global.my_temporary_directory].each_entry do |entry|
            if delete?(entry)
              FileUtils.remove_entry_secure(entry.path)
            end
          end
        end
      end

      # This removes file caches base on cache directory's mtime.
      execution(:remove_file_cache) do |item|
        item.desc = "Remove file cache files"

        item.process do
          test(type?("file-cache"))

          Location[Global.my_file_cache_directory].each_entry do |entry|
            if delete?(entry)
              FileUtils.remove_entry_secure(entry.path)
            end
          end
        end
      end

      execution(:remove_package_cache) do |item|
        item.desc = "Remove package cache files"

        item.condition do
          test(type?("package-cache"))
        end

        # remove PPG packages
        item.process do
          Global.ppg_package_cache_directory.each_entry do |entry|
            unless model[:db].has_digest?(Package::PackageFilename.parse(entry.basename).digest)
              if delete?(entry)
                entry.delete
              end
            end
          end
        end

        # remove directory packages
        item.process do
          Global.directory_package_cache_directory.each_entry do |entry|
            unless model[:db].has_digest?(entry.basename)
              if delete?(entry)
                entry.delete
              end
            end
          end
        end
      end

      execution(:remove_profile) do |item|
        item.desc = "Remove profile reports"

        item.process do
          test(type?("profile"))

          Location[Global.profile_report_directory].each_entry do |entry|
            if delete?(entry)
              entry.delete
            end
          end
        end
      end
    end

    # `PioneCleanContext` is a process context for `pione-clean-context`.
    class PioneCleanContext < Rootage::CommandContext
      # Return true if the type is matched.
      def type?(type)
        model[:type] == "all" or model[:type] == type
      end

      # Return true if the entry should be removed.
      def delete?(entry)
        not(entry.exist?) or model[:older].nil? or model[:older] >= entry.mtime.to_date
      end
    end

    PioneClean.define(:process_context_class, PioneCleanContext)

    PioneCommand.define_subcommand("clean", PioneClean)
  end
end
