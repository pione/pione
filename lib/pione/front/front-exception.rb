module Pione
  module Front
    # FrontError is raised when front server cannnot start.
    class FrontError < StandardError
      def initialize(front, exception)
        @front = front
        @exception = exception
      end

      def message
        "You couldn't start front server(%s): %s" % [@front.class.name, @exception.message]
      end
    end

  end
end
