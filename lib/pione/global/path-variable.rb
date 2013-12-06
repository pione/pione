module Pione
  module Global
    # This is a path of .pione directory.
    define_external_item(:dot_pione_dir) do |item|
      item.desc = "base directory of PIONE's configuration files"
      item.init = "~/.pione"
      item.define_updater do |val|
        Pathname.new(val).expand_path.tap {|path| path.mkpath unless path.exist?}
      end
    end

    # This is a configuration file path.
    define_computed_item(:config_path, [:dot_pione_dir]) do |item|
      item.desc = "configuration file of PIONE"
      item.define_updater {Global.dot_pione_dir + "config.json"}
    end

    # This is a current working directory. The directory is defined by the
    # following rule:
    # - if environment variable "PWD" is defined, use it
    # - if "pwd" command exists, use the command result with logical option
    # - otherwise, Dir.pwd
    define_internal_item(:pwd) do |item|
      item.desc = "path of current system working directory"
      item.define_updater do
        Pathname.new(ENV["PWD"] || `pwd -L`.chomp || Dir.pwd)
      end
    end

    # Temporary directory's root path. PIONE makes various temporary files in
    # the directory with user name under this path, therefore multiple users can
    # set same path to this. Use +Global.my_temporary_directory+ in codes
    # normally.
    define_external_item(:temporary_directory) do |item|
      item.desc = "path of temporary directory"
      item.init = Pathname.new(Dir.tmpdir) + "pione"
      item.define_updater {|val| Pathname.new(val)}
    end

    # This is path of +Global.temporary_directory+ with user name.
    define_computed_item(:my_temporary_directory, [:temporary_directory]) do |item|
      item.desc = "path of user's temporary directory"
      item.define_updater do |val|
        val ? val : Global.temporary_directory + Etc.getlogin
      end
    end

    # This is a generator for action rule working directory.
    define_computed_item(:working_directory_generator, [:my_temporary_directory]) do |item|
      item.desc = "working directory generator"
      item.define_updater do
        Temppath::Generator.new(Global.my_temporary_directory, basename: "working_").tap do |gen|
          gen.unlink = false
        end
      end
    end

    # This is a root path of file cache directory.
    define_external_item(:file_cache_directory) do |item|
      item.desc = "path of file cache directory"
      item.init = Pathname.new(Dir.tmpdir) + "pione-file-cache"
      item.define_updater {|val| Pathname.new(val)}
    end

    # This is a user's file cache directory.
    define_computed_item(:my_file_cache_directory, [:file_cache_directory]) do |item|
      item.desc = "path of user's file cache directory"
      item.define_updater {Global.file_cache_directory + Etc.getlogin}
    end

    # This is a generator for file cache path.
    define_computed_item(:file_cache_path_generator, [:my_file_cache_directory]) do |item|
      item.desc = "file cache path generator"
      item.define_updater do
        Temppath::Generator.new(Global.my_file_cache_directory).tap do |gen|
          gen.unlink = false
        end
      end
    end

    # This is profile report directory.
    define_computed_item(:profile_report_directory, [:dot_pione_dir]) do |item|
      item.desc = "path of profile report directory"
      item.define_updater {|val| val ? val : Global.dot_pione_dir + "profile"}
    end
  end
end

