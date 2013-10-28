module Pione
  module Global
    # Git repository directory
    define_computed_item(:git_repository_directory, [:dot_pione_dir]) do |item|
      item.desc = "path of git repogitory directory"
      item.define_updater do
        Location[Global.dot_pione_dir + "git-repository"]
      end
    end

    # Git package directory
    define_computed_item(:git_package_directory, [:dot_pione_dir]) do |item|
      item.desc = "path of git package directory"
      item.define_updater do
        Location[Global.dot_pione_dir] + "git-package"
      end
    end

    # This is a cache directory path of PPG packages.
    define_computed_item(:ppg_package_cache_directory, [:dot_pione_dir]) do |item|
      item.desc = "path of PPG package cache directory"
      item.define_updater do
        Location[Global.dot_pione_dir] + "ppg-package-cache"
      end
    end

    # This is a cache directory path of directory packages.
    define_computed_item(:directory_package_cache_directory, [:dot_pione_dir]) do |item|
      item.desc = "path of directory package cache directory"
      item.define_updater do
        Location[Global.dot_pione_dir] + "directory-package-cache"
      end
    end

    # This is the location of package database in this system.
    define_computed_item(:package_database_location, [:dot_pione_dir]) do |item|
      item.desc = "location of package database"
      item.define_updater do
        Location[Global.dot_pione_dir] + "package-database.json"
      end
    end
  end
end
