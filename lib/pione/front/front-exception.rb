module Pione
  module Front
    # FrontError is raised when front server cannnot start.
    class FrontError < StandardError

      def message
        "You couldn't start front server(%s)." % self.class.name
      end
    end

  end
end
