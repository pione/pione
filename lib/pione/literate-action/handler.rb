module Pione
  module LiterateAction
    class Handler
      def initialize(action)
        @lang = action[:lang]
        @content = action[:content]
      end

      # Convert the action to a string.
      def textize(domain_info)
        @content.to_s
      end

      # Execute the action.
      def execute(domain_info, dir=Location[Global.pwd])
        text = textize(domain_info)
        location = Location[Temppath.create]
        location.write(("#!/usr/bin/env %s\n" % @lang) + text)
        location.path.chmod(0700)
        `cd #{dir.path}; #{location.path}`
      end
    end
  end
end
