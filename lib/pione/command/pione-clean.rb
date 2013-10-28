module Pione
  module Command
    # PioneClean is a command for clearing temporary files created by PIONE
    # system.
    class PioneClean < BasicCommand
      #
      # basic informations
      #

      command_name "pione-clean"
      command_banner "remove PIONE's temporary files, cache, and etc."
      PioneCommand.add_subcommand("clean", self)

      #
      # options
      #

      use_option :debug

      # --older option
      define_option(:older) do |item|
        item.long = '--older=DATE'
        item.desc = 'remove file older than the date'
        item.default = false
        item.value = proc do |str|
          begin
            Date.iso8601(str)
          rescue ArgumentError
            begin
              Date.today - str.to_i
            rescue
              abort("invalid value of older option: %s" % str)
            end
          end
        end
      end

      # --type option
      define_option(:type) do |item|
        item.long = '--type=NAME'
        item.desc = 'remove only files of the type'
        item.default = false
        item.value = proc do |name|
          case name
          when "temporary"
            :temporary
          when "file-cache"
            :file_cache
          when "package-cache"
            :package_cache
          when "profile"
            :profile
          else
            abort("unknown type: %s" % str)
          end
        end
      end

      #
      # command lifecycle: setup phase
      #

      setup :package_database

      def setup_package_database
        @db = Package::Database.load
      end

      #
      # command lifecycle: execution phase
      #

      execute :remove_temporary
      execute :remove_file_cache
      execute :remove_package_cache
      execute :remove_profile

      # Remove temporary files. This removes working files based on temporary
      # directory's mtime.
      def execute_remove_temporary
        if type?(:temprary)
          Location[Global.my_temporary_directory].each_entry do |entry|
            if delete?(entry)
              FileUtils.remove_entry_secure(entry.path)
            end
          end
        end
      end

      # Remove file cache files. This removes it base on cache directory's mtime.
      def execute_remove_file_cache
        if type?(:file_cache)
          Location[Global.my_file_cache_directory].each_entry do |entry|
            if delete?(entry)
              FileUtils.remove_entry_secure(entry.path)
            end
          end
        end
      end

      # Remove package cache files.
      def execute_remove_package_cache
        if type?(:package_cache)
          # remove PPG package
          Global.ppg_package_cache_directory.each_entry do |entry|
            unless @db.has_digest?(Package::PackageFilename.parse(entry.basename).digest)
              if delete?(entry)
                entry.delete
              end
            end
          end

          # remove directory package
          Global.directory_package_cache_directory.each_entry do |entry|
            unless @db.has_digest?(entry.basename)
              if delete?(entry)
                entry.delete
              end
            end
          end
        end
      end

      # Remove profile reports.
      def execute_remove_profile
        if type?(:profile)
          Location[Global.profile_report_directory].each_entry do |entry|
            if delete?(entry)
              entry.delete
            end
          end
        end
      end

      #
      # helper methods
      #

      # Return true if the entry has the type.
      def type?(type)
        option[:type].nil? or option[:type] == type
      end

      # Return true if the entry should be removed.
      def delete?(entry)
        option[:older].nil? or option[:older] >= entry.mtime.to_date
      end
    end
  end
end
