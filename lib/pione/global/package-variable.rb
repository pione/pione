module Pione
  module Global
    # Git repository directory
    define_internal_item(:git_repository_directory) do
      Location[Global.dot_pione_dir + "git-repository"]
    end

    # Git package directory
    define_internal_item(:git_package_directory) do
      Location[Global.dot_pione_dir] + "git-package"
    end

    # This is a cache directory path of PPG packages.
    define_internal_item(:ppg_package_cache_directory) do
      Location[Global.dot_pione_dir + "ppg-package-cache"]
    end

    # This is a cache directory path of directory packages.
    define_internal_item(:directory_package_cache_directory) do
      Location[Global.dot_pione_dir + "directory-package-cache"]
    end

    # This is the location of package database in this system.
    define_external_item(:package_database_location) do
      Location[Global.dot_pione_dir] + "package-database.json"
    end
  end
end
