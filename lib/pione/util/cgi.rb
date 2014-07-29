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

      # request body
      attr_accessor :body

      def initialize
        @auth_type = nil
        @content_length = nil
        @content_type = nil
        @gateway_interface = "CGI/1.1"
        @path_info = nil
        @path_translated = nil
        @query_string = nil
        @remote_addr = nil
        @remote_host = nil
        @remote_ident = nil
        @remote_user = nil
        @request_method = nil
        @script_name = nil
        @server_name = nil
        @server_port = nil
        @server_protocol = "HTTP/1.1"
        @server_software = "PIONE/%s" % Pione::VERSION
        @body = nil
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
      def initialize(cgi_path, cgi_info, chdir, timeout)
        @cgi_path = cgi_path
        @cgi_info = cgi_info
        @chdir = chdir
        @timeout = timeout
        @umask = 077
        @cgi_stdin = Temppath.new
        @cgi_stdout = Temppath.new
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

        Timeout.timeout(@timeout) do
          @pid = Kernel.spawn(env, @cgi_path, *args, options)
          Process.waitpid(@pid)
          return analyze_response(Location[@cgi_stdout].read)
        end
      rescue Timeout::Error
        if @pid
          begin
            Process.kill(15, @pid)
          rescue
          end
        end
      end

      private

      def nph?
        Pathname.new(@cgi_path).basename.start_with?("nph-")
      end

      def create_options
        options = Hash.new
        options[:chdir] = @chdir
        options[:umask] = @umask
        if @cgi_info.body
          Location[@cgi_in].write(@cgi_info.body)
          options[:in] = @cgi_stdin.path
        end
        options[:out] = @cgi_stdout.path
      end

      def analyze_response(stdout)
        cgi_response = new CGIResponse

        if nph?
          cgi_response.nph = true
          cgi_response.body = stdout
        else
          cgi_response.nph = false

          # parse headers
          headers, body = stdout.split(/(\r\n\r\n|\r\r|\n\n)/, 2)
          header = headers.split(/(\r\n|\r|\n)/).each_with_object(Hash.new) do |line, table|
            name, value = line.split(/:[\s\t]*/, 2)
            if name.nil? or name.size == 0 or /\s/.match?(name) or value.nil?
              raise CGIError.invalid_response_header(line)
            else
              table[name.downcase] = value
            end
          end

          # content-type
          if header.has_key?("content-type")
            cgi_response.content_type = header["content-type"]
          else
            raise CGIError.content_type_not_found
          end

          # location
          if header["location"]
            begin
              uri = URI.parse(header["location"])
              cgi_response.location = header["location"]
            rescue
              raise CGIError.invalid_location(header["location"])
            end
          end

          # status
          if header["status"]
            code, reason_phrase = status.split(/\s+/, 2)
            if /\d\d\d/.match(code)
              cgi_response.status_code = code
              cgi_response.reason_phrase = reason_phrase
            else
              raise CGIError.invalid_status(code)
            end
          end
        end

        return cgi_response
      end
    end

    class CGIResponse
      attr_accessor :nph
      attr_accessor :content_type
      attr_accessor :location
      attr_accessor :status_code
      attr_accessor :reason_phrase
      attr_accessor :body

      def initialize
        @nph = false
        @content_type = nil
        @location = nil
        @status_code = 200
        @reason_phrase = nil
        @response_body = nil
      end

      def valid?
        not(@content_type.nil?)
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

      def self.invalid_response_header(line)
        new("Inlivad CGI response header has found: \"%s\"" % line)
      end

      def self.content_type_not_found
        new("Requisite CGI response header \"Content-Type\" has not found.")
      end

      def self.invalid_location(value)
        new("Invalid location has found: \"%s\"" % value)
      end

      def self.invalid_status(code)
        new("Invalid status code has found: \"%s\"" % code)
      end
    end
  end
end
