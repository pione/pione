module Pione
  module Location
    class HTTPSLocation < HTTPLocation
      set_scheme "https"

      define(:need_caching, true)
      define(:real_appendable, false)
      define(:writable, false)

      # Send a request HTTPS Get and evaluate the block with the response.
      def http_get(&b)
        http = Net::HTTP.new(@uri.host, @uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        req = Net::HTTP::Get.new(@uri.path)
        res = http.request(req)
        if res.kind_of?(Net::HTTPSuccess)
          return b.call(res)
        else
          raise NotFound.new(@uri)
        end
      end

      # Send a request HTTPS Head and evaluate the block with the response.
      def http_head(&b)
        http = Net::HTTP.new(@uri.host, @uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        req = Net::HTTP::Head.new(@uri.path)
        res = http.request(req)
        if res.kind_of?(Net::HTTPSuccess)
          return b.call(res)
        else
          raise NotFound(@uri)
        end
      end
    end
  end
end
