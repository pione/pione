module Pione
  module Location
    class HTTPLocation < DataLocation
      set_scheme "http"

      define(:need_caching, true)
      define(:real_appendable, false)
      define(:writable, false)

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

      def copy(dest, option={})
        # setup options
        option[:keep_mtime] = true if option[:keep_mtime].nil?

        # copy
        http_get {|rec| dest.write rec.body}

        # modify mtime
        dest.mtime = self.mtime if option[:keep_mtime]
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
