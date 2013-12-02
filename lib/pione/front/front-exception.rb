module Pione
  module Front
    # `Front::Error` is a base exception class.
    class Error < StandardError; end

    # FrontError is raised when front server cannnot start.
    class FrontServerError < Error
      def initialize(front, exception)
        @front = front
        @exception = exception
      end

      def message
        "You couldn't start front server(%s): %s" % [@front.class.name, @exception.message]
      end
    end

    # `ChildRegistrationError` is raised when child process failed to register to
    # parent front.
    class ChildRegistrationError < Error; end
  end
end
