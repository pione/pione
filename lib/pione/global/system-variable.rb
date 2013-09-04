module Pione
  module Global
    #
    # system
    #

    # @!method monitor
    # Global monitor object for PIONE system.
    #
    # @return [Monitor]
    #   monitor object
    define_item(:monitor, false, Monitor.new)

    # exist status
    define_item(:exit_status, true, true)

    # .pione dir
    define_item(:dot_pione_dir, true) do
      Pathname.new("~/.pione").expand_path.tap {|path|
        path.mkpath unless path.exist?
      }
    end

    # config path
    define_item(:config_path, true) do
      Global.dot_pione_dir + "config.yml"
    end

    # @!method temporary_directory_root
    #
    # Temporary directory's root path. You can change temporary directories
    # paths by setting this variable.
    #
    # @return [Pathname]
    #   root of all temporary directories
    #
    # @example
    #   Global.temporary_directory_root #=> "/tmp/pione"
    define_item(:temporary_directory_root, true, Pathname.new(Dir.tmpdir) + "pione")

    # @!method temporary_directory
    #
    # Temporary directory for various processings.
    #
    # @return [Pathname]
    #   temporary directory
    #
    # @example
    #   Global.temporary_directory #=> "/tmp/pione/misc_keita"
    define_item(:temporary_directory, false) do
      Global.temporary_directory_root + "misc_%s" % Etc.getlogin
    end

    # @!method working_directory_root
    #
    # Root of working directory. This directory is created by each user.
    #
    # @return [Pathname]
    #   root of working directory
    #
    # @example
    #   Global.working_directory_root #=> "/tmp/pione/working_keita"
    define_item(:working_directory_root, false) do
      dir = Global.temporary_directory_root + "working_%s" % Etc.getlogin
      Pathname.new(dir).tap {|path| path.mkpath unless path.exist?}
    end

    # @!method working_directory
    #
    # Working directory for action rules.
    #
    # @return [Pathname]
    #   working directory
    #
    # @example
    #   Global.working_directory #=> "/tmp/pione/working_keita/d20130404-10000-1kg2ezo"
    define_item(:working_directory, false) do
      Pathname.new(Dir.mktmpdir(nil, Global.working_directory_root))
    end

    # @!method file_cache_directory_root
    #
    # Root of file cache directory. This directory is created by each user.
    #
    # @return [Pathname]
    #   root of file cache directory
    #
    # @example
    #   Global.file_cache_directory_root #=> "/tmp/pione/file-cache_keita"
    define_item(:file_cache_directory_root, false) do
      dir = Global.temporary_directory_root + "file-cache_%s" % Etc.getlogin
      Pathname.new(dir).tap {|path| path.mkpath unless path.exist?}
    end

    # @!method file_cache_directory
    #
    # File cache directory.
    #
    # @return [Pathname]
    #   file cache directory
    #
    # @example
    #   Global.file_cache_directory #=> "/tmp/pione/file-cache_keita/d20130404-11086-qtu7h0"
    define_item(:file_cache_directory, false) do
      Pathname.new(Dir.mktmpdir(nil, Global.file_cache_directory_root))
    end

    # Git repository directory
    define_item(:git_repository_directory, false) do
      Location[Global.dot_pione_dir + "git-repository"]
    end

    # Git package directory
    define_item(:git_package_directory, false) do
      Location[Global.dot_pione_dir] + "git-package"
    end

    # archive_package_cache_dir
    define_item(:archive_package_cache_dir, false) do
      Location[Global.dot_pione_dir + "archive-package-cache"]
    end

    # system front server
    define_item(:front, false)

    # IP address of this system.
    # NOTE: you should select one IP address if system has multiple addresses
    define_item(:my_ip_address, true) do
      Util::IPAddress.myself
    end

    # This means current working directory. The directory is defined by the
    # following rule:
    # - 1. if environment variable "PWD" is defined, use it
    # - 2. if "pwd" command exists, use the command result with logical option
    # - 3. otherwise Dir.pwd
    define_item(:pwd, false) do
      (ENV["PWD"] || `pwd -L`.chomp || Dir.pwd)
    end

    #
    # system log
    #
    define_item(:system_logger, true) do
      Log::StandardSystemLogger.new(STDOUT)
    end
  end
end
