module Pione
  module URIScheme
    # GitScheme is a scheme for PIONE package in git repository.
    #
    # @example
    #   URI.parse("git://github.com/pione/pione.git")
    class GitScheme < BasicScheme('git', :storage => false)

      COMPONENT = [:scheme, :host, :port, :path]
    end
  end
end
