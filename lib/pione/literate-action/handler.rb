module Pione
  module LiterateAction
    # Handler handles action documents.
    class Handler
      def initialize(action)
        @lang = action[:lang] || "sh"
        @content = action[:content]
      end

      # Convert the action to a string.
      def textize(domain_info)
        @content.to_s
      end

      # Execute the action.
      def execute(domain_info, dir=Location[Global.pwd])
        location = Location[Temppath.create]
        location.write(("#!/usr/bin/env %s\n" % @lang) + textize(domain_info))
        location.path.chmod(0700)

        system(location.path.to_s, chdir: dir.path)
      end
    end
  end
end
