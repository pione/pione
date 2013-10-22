module Pione
  module Global
    # This is a path of .pione directory.
    define_external_item(:dot_pione_dir) do
      Pathname.new("~/.pione").expand_path.tap {|path|
        path.mkpath unless path.exist?
      }
    end

    # This is a configuration file path.
    define_external_item(:config_path) {Global.dot_pione_dir + "config.yml"}

    # This is a current working directory. The directory is defined by the
    # following rule:
    # - if environment variable "PWD" is defined, use it
    # - if "pwd" command exists, use the command result with logical option
    # - otherwise, Dir.pwd
    define_internal_item(:pwd) {(ENV["PWD"] || `pwd -L`.chomp || Dir.pwd)}

    # Temporary directory's root path. You can change temporary directories
    # paths by setting this variable.
    define_external_item(:temporary_directory_root, Pathname.new(Dir.tmpdir) + "pione")

    # Temporary directory for various processings.
    define_internal_item(:temporary_directory) do
      Global.temporary_directory_root + "misc_%s" % Etc.getlogin
    end

    # Root of working directory. This directory is created by each user.
    define_external_item(:working_directory_root) do
      dir = Global.temporary_directory_root + "working_%s" % Etc.getlogin
      Pathname.new(dir).tap {|path| path.mkpath unless path.exist?}
    end

    # Working directory for action rules.
    define_internal_item(:working_directory) do
      Pathname.new(Dir.mktmpdir(nil, Global.working_directory_root))
    end

    # Root of file cache directory. This directory is created by each user.
    define_internal_item(:file_cache_directory_root) do
      dir = Global.temporary_directory_root + "file-cache_%s" % Etc.getlogin
      Pathname.new(dir).tap {|path| path.mkpath unless path.exist?}
    end

    # File cache directory.
    define_internal_item(:file_cache_directory) do
      Pathname.new(Dir.mktmpdir(nil, Global.file_cache_directory_root))
    end

    # This is profile report directory.
    define_internal_item(:profile_report_directory) {Global.dot_pione_dir + "profile"}
  end
end

