module Pione
  module Util
    # This is a store of CGI meta-variables based on RFC3875.
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

      # CGI meta-variable "SERVER_SOFTWARE"
      attr_accessor :server_software

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
        @server_software = "PIONE/%s" % Pione::VERSION
      end

      def create_env
        env = @cgi_info.create_env
        env["AUTH_TYPE"] = @auth_type if @auth_type
        env["CONTENT_LENGTH"] = @content_length if @content_length
        env["CONTENT_TYPE"] = @content_type if @content_type
        env["GATEWAY_INTERFACE"] = @gateway_interface
        env["PATH_INFO"] = @path_info
        env["REMOTE_ADDR"] = @remote_addr
        env["REMOTE_USER"] = @remote_user if @remote_user
        env["REQUEST_METHOD"] = @request_method.to_s
        env["SCRIPT_NAME"] = @script_name
        env["SERVER_NAME"] = @server_name
        env["SERVER_PORT"] = @server_port
        env["SERVER_PROTOCOL"] = @server_protocol
        env["SERVER_SOFTWARE"] = @server_software
      end
    end

    class CGI
      # @param [Pathname] path
      #   path of the CGI program
      # @param [Hash] params
      #   paramters to pass to the CGI program
      def initialize(cgi_path, params, cgi_info)
        @cgi_path = cgi_path
        @parmas = params
        @cgi_info = cgi_info
      end

      # Execute the CGI program.
      def exec
        unless cgi_path.exist?
          raise CGIError.not_exist
        end

        env = @cgi_info.create_env
        status = Kernel.system(env, @cgi_path)
      end
    end
  end
end
