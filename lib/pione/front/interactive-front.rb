module Pione
  module Front
    # InteractiveFront is a front interface for +pione-interactive+ command.
    class InteractiveFront < BasicFront
      def initialize(cmd)
        super(cmd, Global.interactive_front_port_range)
      end

      # Read data string from the path. This path should be relative from public
      # directory of pione-interactive.
      #
      # @param [String] path
      #   relative path from public directory
      def get(path)
        begin
          (@cmd.model[:public] + path).read
        rescue
          return nil
        end
      end

      # Create a file with the content. Thie operation returns true only if the
      # file creation has succeeded.
      def create(path, content)
        begin
          (@cmd.model[:public] + path).write(content)
          return true
        rescue => e
          return false
        end
      end

      # Delete the file. Thie operation returns true only if the file deletion
      # has succeeded.
      def delete(path)
        begin
          (@cmd.model[:public] + path).delete
          return true
        rescue => e
          return false
        end
      end

      # Return entry informations in the directory. When the operation returns
      # nil, the file listing has failed. When this returns false, the path is
      # file.
      def list(path)
        begin
          unless (@cmd.model[:public] + path).directory?
            return false
          end

          (@cmd.model[:public] + path).entries.map do |entry|
            { "name"  => entry.basename,
              "type"  => entry.directory? ? "dir" : "file",
              "mtime" => entry.mtime.iso8601,
              "size"  => entry.size }
          end
        rescue => e
          return nil
        end
      end
    end
  end
end
