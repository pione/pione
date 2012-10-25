# URI extention for PIONE system.
# @api private
module URI
  # Installs a new scheme.
  def self.install_scheme(name, klass)
    @@schemes[name] = klass
  end

  class Parser
    alias :orig_split :split

    # special split method for local scheme.
    def split(uri)
      if uri.split(":").first == "local"
        scheme = "local"
        path = uri[6..-1]
        return [scheme, nil, nil, nil, nil, path, nil, nil, nil]
      else
        return orig_split(uri)
      end
    end
  end
end
