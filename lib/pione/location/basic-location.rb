module Pione
  module Location
    # known schemes table
    SCHEMES = {}

    class << self
      # Return the location object corresponding to the address.
      #
      # @param address [URI,String]
      #   URI or location address
      # @return [BasicLocation]
      #   location object
      def [](address)
        if address.kind_of?(Hash)
          return create_git_repository_location(address) if address[:git]
          return create_data_location(address[:data]) if address[:data]
        else
          return create_data_location(address)
        end
      end

      private

      # Return the resource location.
      def create_data_location(address)
        uri = URI.parse(address.to_s)
        uri = uri.scheme ? uri : URI.parse("local:%s" % Pathname.new(uri.path).expand_path)
        if location_class = SCHEMES[uri.scheme]
          location_class.new(uri)
        else
          raise ArgumentError.new(uri)
        end
      end

      # Return the git repository location.
      def create_git_repository_location(address)
        GitRepositoryLocation.new(address)
      end
    end

    # BasicLocation is a class for all location classes.
    class BasicLocation
      class << self
        # Set location type.
        #
        # @param name [Symbol]
        #   location type name
        # @return [void]
        def location_type(name=nil)
          if name
            @location_type = name
          else
            @location_type ? @location_type : superclass.location_type
          end
        end
      end

      forward :class, :location_type
      attr_reader :address

      # Create a location with the URI.
      #
      # @param uri [URI]
      #   location URI
      def initialize(address)
        @address = address
      end

      # @api private
      def inspect
        "#<%s %s>" % [self.class, address]
      end
      alias :to_s :inspect

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        @address == other.address
      end
      alias :eql? :"=="

      # @api private
      def hash
        @address.hash
      end
    end
  end
end
