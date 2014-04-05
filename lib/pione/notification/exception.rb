module Pione
  module Notification
    # `Notification::Error` is a base exception class related notification
    # errors.
    class Error < StandardError; end

    # `Notification::MessageError` is a error for message format.
    class MessageError < Error; end
  end
end
