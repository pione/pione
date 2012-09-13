module Pione
  module Util
    # Terminal is a set of utility methods for displaying characters in terminal.
    module Terminal
      # @api private
      @@color_mode = true

      # Sets color mode.
      #
      # @param [bool] bool
      #   whether color mode is true
      # @return [void]
      def color_mode=(bool)
        @@color_mode = bool
      end
      module_function :color_mode=

      # Returns a colored string.
      #
      # @param [Symbol] color
      #   color name
      # @param [String] str
      #   target string
      # @return [String]
      def color(color, str)
        case color
        when :red
          red(str)
        when :green
          green(str)
        when :magenta
          magenta(str)
        else
          str
        end
      end
      module_function :color

      # Returns a red colored string.
      #
      # @param [String] str
      #   target string
      # @return [String]
      def red(str)
        colorize(str, "\x1b[31m", "\x1b[39m")
      end
      module_function :red

      # Returns a green colored string.
      #
      # @param [String] str
      #   target string
      # @return [String]
      def green(str)
        colorize(str, "\x1b[32m", "\x1b[39m")
      end
      module_function :green

      # Returns a magenta colored string.
      #
      # @param [String] str
      #   target string
      # @return [String]
      def magenta(str)
        colorize(str, "\x1b[35m", "\x1b[39m")
      end
      module_function :magenta

      private

      # @api private
      def colorize(str, bc, ec)
        @@color_mode ? bc + str + ec : str
      end
      module_function :colorize
    end
  end
end
