module Pione
  module Location
    class HTTPLocation < BasicLocation
      set_scheme "http"
      set_real_appendable false
      set_writable false

      def read
        http_get {|res| res.body}
      end

      def mtime
        http_head {|res| Time.httpdate(res['last-modified']) }
      end

      def size
        http_head {|res| res.content_length } || read.size
      end

      def exist?
        http_head {|res| true}
      rescue
        false
      end

      def file?
        exist?
      end

      def directory?
        false
      end

      def copy(dest)
        http_get {|rec| dest.write rec.body}
      end

      private

      # Send a request HTTP Get and evaluate the block with the response.
      def http_get(&b)
        http = Net::HTTP.new(@uri.host, @uri.port)
        req = Net::HTTP::Get.new(@uri.path)
        res = http.request(req)
        if res.kind_of?(Net::HTTPSuccess)
          return b.call(res)
        else
          raise NotFound.new(@uri)
        end
      end

      # Send a request HTTP Head and evaluate the block with the response.
      def http_head(&b)
        http = Net::HTTP.new(@uri.host, @uri.port)
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
