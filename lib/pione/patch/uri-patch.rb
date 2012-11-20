# URI extention for PIONE system.
# @api private
module URI
  # Installs a new scheme.
  def self.install_scheme(name, klass)
    @@schemes[name] = klass
  end

  class Generic
    # Returns true if the scheme is supportted by PIONE system.
    # @return [Boolean]
    #   true if the scheme is supportted by PIONE system
    def pione?
      false
    end

    # Returns true if the path represents a directory.
    # @return [Boolean]
    #   true if the path represents a directory
    def directory?
      path[-1] == '/'
    end

    # Returns true if the path represents a file.
    # @return [Boolean]
    #   true if the path represents a file
    def file?
      not(directory?)
    end

    # Converts the uri into directory form.
    # @return [Generic]
    #   directory path form
    def as_directory
      if directory?
        self
      else
        self.clone.tap{|s| s.path = s.path + "/"}
      end
    end
  end

  class Parser
    alias :orig_split :split

    # Handles to split special schemes's URI.
    def split(uri)
      scheme = uri.split(":").first

      # special schemes
      case scheme
      when "local"
        path = uri[6..-1]
        return [scheme, nil, nil, nil, nil, path, nil, nil, nil]
      when "broadcast"
        rest = uri[10..-1]
        if rest == "//"
          return [scheme, nil, nil, nil, nil, nil, nil, nil, nil]
        end
      end

      # other case
      return orig_split(uri)
    end
  end
end
