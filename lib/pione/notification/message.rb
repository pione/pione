module Pione
  module Notification
    class Message
      PROTOCOL_VERSION = "PN1"

      # Load a notification from the dumped data.
      #
      # @param data [String]
      #   dumped data
      # @return [Network::Notification]
      #   notification object
      def self.load(data)
        io = StringIO.new(data)

        # read
        total = io.read(2).unpack("n")[0]
        psize = io.read(1).unpack("C")[0]
        version = io.read(psize)
        nsize = io.read(1).unpack("C")[0]
        notifier = io.read(nsize)
        tsize = io.read(1).unpack("C")[0]
        type = io.read(tsize)
        msize = io.read(2).unpack("n")[0]
        json = io.read(msize)

        # check size
        unless total == psize + nsize + tsize + msize
          raise MessageError.new("Total size and real message size are different.")
        end

        # convert json to ruby object
        begin
          content = JSON.parse(json)
        rescue JSON::ParserError
          MessageError.new("Format of the message content is invalid.")
        end

        new(notifier, type, content)
      end

      attr_reader :notifier
      attr_reader :type
      attr_reader :version

      # @param notifier [String]
      #   name of notification sender
      # @param type [String]
      #   notification type name
      # @param message [Hash]
      #   JSON data
      # @param version [String]
      #   protocol version
      def initialize(notifier, type, content, version=PROTOCOL_VERSION)
        @notifier = notifier
        @type = type
        @content = content
        @version = version
      end

      # Return the value.
      #
      # @param name [String]
      #   key of message content
      # @return [Object]
      #   the value
      def [](name)
        @content[name]
      end

      # Dump the notification message to a serialized string.
      #
      # @return [String]
      #   a serialized string
      def dump
        json = JSON.generate(@content)

        psize = PROTOCOL_VERSION.bytesize
        nsize = @notifier.bytesize
        tsize = @type.bytesize
        msize = json.bytesize
        total = psize + nsize + tsize + msize

        if nsize > 255
          raise MessageError.new('notifier "%s" is too long.' % @notifier)
        end

        if tsize > 255
          raise MessageError.new('type "%s" is too long.' % @type)
        end

        if msize > 65335
          raise MessageError.new('message is too long.')
        end

        if total > 65535
          raise MessageError.new('The notification is too long.')
        end

        # build a serialized string
        data = ""
        data << [total].pack("n")
        data << [psize].pack("C") << PROTOCOL_VERSION
        data << [nsize].pack("C") << @notifier
        data << [tsize].pack("C") << @type
        data << [msize].pack("n") << json
      end
    end
  end
end
