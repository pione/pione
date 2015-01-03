module Pione
  module LiterateAction
    # Handler handles action documents.
    class Handler
      def initialize(action)
        @lang = action[:lang] || "sh"
        @content = action[:content]
      end

      # Convert the action to a string.
      def textize(domain_dump)
        @content.to_s
      end

      # Execute the action.
      #
      # @param options [Hash]
      #   the options
      # @option options [DomainDump] :domain_dump
      #   domain dump
      # @option options [Loacation] :chdir
      #   the location of working directory for action
      # @option options [Location] :out
      #   the file writing STDOUT
      # @return [Boolean]
      #   true if the action succeeded
      def execute(options={})
        location = Location[Temppath.create]
        location.write(("#!/usr/bin/env %s\n" % @lang) + textize(options[:domain_dump]))
        location.path.chmod(0700)

        _options = {}
        _options[:chdir] = options[:chdir] ? options[:chdir].path.to_s : Location[Global.pwd].path.to_s
        _options[:out] = options[:out].path.to_s if options.has_key?(:out)

        return system(location.path.to_s, _options)
      end
    end
  end
end
