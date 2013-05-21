module Pione
  module URIScheme
    # MyFTPScheme is a special scheme for launching PIONE embedded ftp server.
    #
    # @example
    #   URI.parse("myftp:./output")
    # @example
    #   URI.parse("myftp://abc:123@192.168.0.32:45321/home/keita/pione/output")
    class MyFTPScheme < BasicScheme('myftp', :storage => true)
      PORT = 39123

      COMPONENT = [:scheme, :user, :password, :host, :port, :path]

      # Normalize the URI.
      #
      # @return [URI]
      #   normalized URI
      def normalize
        hash = {
          :scheme => "myftp",
          :userinfo => userinfo || Util::FTPServer.auth_info.to_userinfo,
          :host => (host == "myself" or host.nil?) ? Util::IPAddress.myself : host,
          :port => port || PORT,
          :path => File.expand_path(path, Global.pwd) + (directory? ? "/" : "")
        }
        MyFTPScheme.build(hash)
      end

      # Return ftp scheme that refers the ftp server.
      #
      # @return [URI]
      #   ftp scheme URI
      def to_ftp_scheme
        hash = {
          :scheme => "ftp",
          :userinfo => userinfo || Util::FTPServer.auth_info.to_userinfo,
          :host => (host == "myself" or host.nil?) ? Util::IPAddress.myself : host,
          :port => port || PORT,
          :path => "/"
        }
        URI::FTP.build(hash)
      end
    end
  end
end
