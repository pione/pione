module Pione
  module URIScheme
    # BasicScheme is a URI scheme for PIONE.
    class BasicScheme < ::URI::Generic
      # Returns true always because classes inheriting BasicScheme are supported
      # by PIONE system.
      # @api private
      def pione?
        true
      end

      # Returns true if the scheme acts as storage.
      # @return [Boolean]
      #   true if the scheme acts as storage
      def storage?
        self.class.instance_variable_get(:@storage)
      end
    end

    # Returns a new scheme. Use this method for inheriting BasicScheme if you
    # create new scheme.
    # @return [Class]
    def BasicScheme(name, opts={})
      klass = Class.new(BasicScheme)

      def klass.inherited(scheme)
        name = self.instance_variable_get(:@scheme_name)
        URI.install_scheme(name.upcase, scheme)
        scheme.instance_variable_set(:@storage, @storage)
      end

      klass.instance_variable_set(:@scheme_name, name.upcase)
      storage_flag = opts[:storage] || false
      klass.instance_variable_set(:@storage, storage_flag)

      return klass
    end
    module_function :BasicScheme
  end
end
