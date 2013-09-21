module Pione
  module LocationScheme
    # GitScheme is a scheme for PIONE package in git repository.
    #
    # @example
    #   URI.parse("git://github.com/pione/pione.git")
    class GitScheme < LocationScheme('git', :storage => false)

      COMPONENT = [:scheme, :host, :port, :path]
    end
  end
end
