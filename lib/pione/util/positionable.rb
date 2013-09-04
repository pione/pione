module Pione
  module Util
    # Positionable provides the function that stores its source position
    # information to objects.
    module Positionable
      # Set source position informations of the object.
      #
      # @example Specify package name, filename, line number, and column number
      #   obj = Object.new.tap {|x| x.extend Positionable}
      #   obj.set_source_position("HelloWorld", "HelloWorld.pione", 1, 1)
      #
      # @example SourcePosition object
      #   obj = Object.new.tap {|x| x.extend Positionable}
      #   obj.set_source_position(other.pos)
      def set_source_position(*args)
        if args.size == 1 and args[0].is_a?(SourcePosition)
          @__source_position__ = args[0]
        elsif args.size > 0
          @__source_position__ = SourcePosition.new(*args)
        end
      end

      # Return the source position.
      def pos
        @__source_position__ || SourcePosition.unknown
      end

      # Return the line and column. If source position isn't established, return
      # nil simply.
      def line_and_column
        if @__source_position__
          return @__source_position__.line, @__source_position__.column
        end
      end
    end

    # SourcePosition represents source position model of PIONE and defines its
    # string format.
    class SourcePosition < StructX
      class << self
        def unknown
          @unknown ||= UnknownSourcePosition.new
        end
      end

      member :package_name
      member :filename
      member :line
      member :column

      def format
        args = [package_name, filename, line, column]
        "(package %s, file %s, line %s, column %s)" % args
      end
    end

    class UnknownSourcePosition < StructX
      member :dummy

      def format
        ""
      end
    end
  end
end
