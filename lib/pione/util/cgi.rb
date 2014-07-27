module Pione
  module Util
    module CGIUtils
      def self.decode(string)
        URI.decode_www_form_component(string)
      end
    end

    # CGIInfo is a store of CGI meta-variables based on RFC3875.
    class CGIInfo
      # CGI meta-variable "AUTH_TYPE"
      attr_accessor :auth_type

      # CGI meta-variable "CONTENT_LENGTH"
      attr_accessor :content_length

      # CGI meta-variable "CONTENT_TYPE"
      attr_accessor :content_type

      # CGI meta-variable "GATEWAY_INTERFACE"
      attr_accessor :gateway_interface

      # CGI meta-variable "PATH_INFO"
      attr_accessor :path_info

      # CGI meta-variable "PATH_TRANSLATED"
      attr_accessor :path_translated

      # CGI meta-variable "QUERY_STRING"
      attr_accessor :query_string

      # CGI meta-variable "REMOTE_ADDR"
      attr_accessor :remote_addr

      # CGI meta-variable "REMOTE_HOST"
      attr_accessor :remote_host

      # CGI meta-variable "REMOTE_IDENT"
      attr_accessor :remote_ident

      # CGI meta-variable "REMOTE_USER"
      attr_accessor :remote_user

      # CGI meta-variable "REQUEST_METHOD"
      attr_accessor :request_method

      # CGI meta-variable "SCRIPT_NAME"
      attr_accessor :script_name

      # CGI meta-variable "SERVER_NAME"
      attr_accessor :server_name

      # CGI meta-variable "SERVER_PORT"
      attr_accessor :server_port

      # CGI meta-variable "SERVER_PROTOCOL"
      attr_accessor :server_protocol

      # CGI meta-variable "SERVER_SOFTWARE"
      attr_accessor :server_software

      # HTTP specific variable table
      attr_accessor :http_header

      def initialize
        @auth_type = nil
        @content_length = nil
        @content_type = nil
        @gateway_interface = "CGI/1.1"
        @path_info = nil
        @path_translated = nil # not supported
        @query_string = nil
        @remote_addr = nil
        @remote_host = nil # (SHOULD) not supported
        @remote_ident = nil # (MAY)
        @remote_user = nil # pione-webclient's user name
        @request_method = nil # (MUST) "GET" | "POST" | "HEAD"
        @script_name = nil # (MUST)
        @server_name = nil # (MUST)
        @server_port = nil # (MUST)
        @server_protocol = "HTTP/1.1"
        @server_software = "PIONE/%s" % Pione::VERSION
      end

      # Create environment variables.
      # @return [Hash]
      #   environment variables
      def create_env
        env = Hash.new

        # store CGI meta-variables
        env["AUTH_TYPE"] = @auth_type if @auth_type
        env["CONTENT_LENGTH"] = @content_length if @content_length
        env["CONTENT_TYPE"] = @content_type if @content_type
        env["GATEWAY_INTERFACE"] = @gateway_interface
        env["PATH_INFO"] = @path_info
        env["PATH_TRANSLATED"] = @path_translated
        env["QUERY_STRING"] = @query_string
        env["REMOTE_ADDR"] = @remote_addr
        env["REMOTE_HOST"] = @remote_host
        env["REMOTE_IDENT"] = @remote_ident if @remote_ident
        env["REMOTE_USER"] = @remote_user if @remote_user
        env["REQUEST_METHOD"] = @request_method.to_s
        env["SCRIPT_NAME"] = @script_name
        env["SERVER_NAME"] = @server_name
        env["SERVER_PORT"] = @server_port
        env["SERVER_PROTOCOL"] = @server_protocol
        env["SERVER_SOFTWARE"] = @server_software

        # store HTTP specific variables
        @http_header.each do |key, val|
          env["HTTP_%s" % key] = val
        end
      end

      def create_arguments
        unless @query_string.include?("=")
          return @query_string.split("+").map do |arg|
            begin
              CGIUtils.decode(arg)
            rescue
              raise CGIError.failed_to_decode(@query_string)
            end
          end
        end

        return []
      end
    end

    # CGIExecutor is a execution helper for CGI programs.
    class CGIExecutor
      # @param [Pathname] cgi_path
      #   path of the CGI program
      # @param [CGIInfo] cgi_info
      #   various informations for CGI program
      def initialize(cgi_path, cgi_info, chdir)
        @cgi_path = cgi_path
        @cgi_info = cgi_info
        @chdir = chdir
        @umask = 077
        @tempfile = Temppath.new
        @pid = nil
      end

      # Execute the CGI program.
      def exec
        unless cgi_path.exist?
          raise CGIError.not_exist(@cgi_path)
        end

        env = @cgi_info.create_env
        options = create_options
        args = @cgi_info.create_arguments

        @pid = Kernel.spawn(env, @cgi_path, *args, options)
        exit_code = Process.waitpid(@pid)
        return Location[@tempfile].read
      end

      private

      def create_options
        options = Hash.new
        options[:chdir] = @chdir
        options[:umask] = @umask
        options[:out] = @tempfile.path
      end
    end

    # CGIError is an error class for occuring errors of CGI execution.
    class CGIError < StandardError
      def self.not_exist(path)
        new("CGI program not exist at %s." % path)
      end

      def self.failed_to_decode(string)
        new("Failed to decode the string as URL: %s" % string)
      end
    end
  end
end
