module Pione
  module Command
    # PioneClean is a command for clearing temporary files created by PIONE
    # system.
    class PioneClean < BasicCommand
      #
      # basic informations
      #

      command_name "pione-clean"
      command_banner "Clean working directories and file cache directories."

      #
      # options
      #

      use_option :debug

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

      execute :remove_working_directory
      execute :remove_cache_directory
      execute :remove_ppg_cache
      execute :remove_directory_cache
      execute :remove_profile_reports

      def execute_remove_working_directory
        FileUtils.remove_entry_secure(Global.working_directory_root)
      end

      def execute_remove_cache_directory
        FileUtils.remove_entry_secure(Global.file_cache_directory_root)
      end

      def execute_remove_ppg_cache
        Global.ppg_package_cache_directory.each_entry do |entry|
          unless @db.has_digest?(Package::PackageFilename.parse(entry.basename).digest)
            entry.delete
          end
        end
      end

      def execute_remove_directory_cache
        Global.directory_package_cache_directory.each_entry do |entry|
          unless @db.has_digest?(entry.basename)
            entry.delete
          end
        end
      end

      def execute_remove_profile_reports
        Location[Global.profile_report_directory].each_entry do |entry|
          entry.delete
        end
      end
    end
  end
end
