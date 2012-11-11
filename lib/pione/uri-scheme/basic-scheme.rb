module Pione
  module URIScheme
    # BasicScheme is a URI scheme for PIONE.
    class BasicScheme < ::URI::Generic; end

    # Returns a new scheme. Use this method for inheriting BasicScheme if you
    # create new scheme.
    # @return [Class]
    def BasicScheme(name)
      klass = Class.new(BasicScheme)

      def klass.inherited(scheme)
        name = self.instance_variable_get(:@scheme_name)
        URI.install_scheme(name.upcase, scheme)
      end

      klass.instance_variable_set(:@scheme_name, name.upcase)
      return klass
    end
    module_function :BasicScheme
  end
end
