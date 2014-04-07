module Pione
  module Command
    class PioneInteractive < BasicCommand
      #
      # libraries
      #

      require 'rexml/document'

      # debug mode only
      unless ENV["PIONE_JOB_ID"]
        require 'webrick'
      end

      #
      # informations
      #

      define(:toplevel, true)
      define(:name, "pione-interactive")
      define(:desc, "interactive action handler")

      #
      # arguments
      #

      argument(:xml) do |item|
        item.type    = :location
        item.desc    = "UI definition file"
        item.missing = "There are no definition file."
      end

      #
      # options
      #

      option(:ui) do |item|
        item.type = :symbol_downcase
        item.long = "--ui"
        item.arg  = "NAME"
        item.desc = "User interface name"
      end

      option_post(:validate_ui) do |item|
        item.desc = "Validate UI name"

        item.process do
          test(model[:ui].nil?)
          raise Rootage::OptionError.new(cmd, "No UI name")
        end

        item.process do
          test(model[:ui] != :browser)
          raise Rootage::OptionError.new(cmd, "Unknown UI name: %s" % model[:ui])
        end
      end

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |seq|
        seq << :ui_definition
      end

      setup(:ui_definition) do |item|
        item.desc = "Extract informations from UI definition"
        item.process do
          fm = REXML::Formatters::Default.new

          # create a document
          doc = REXML::Document.new(model[:xml].read)

          # get the prefix of root element(e.g. "pione")
          prefix = doc.root.prefix
          prefix = prefix ? prefix + ":" : ""

          # get embeded contents
          content = REXML::XPath.first(doc, "/#{prefix}interactive/#{prefix}content")
          model[:content] = ""
          content.elements.each {|e| fm.write(e, model[:content])}

          # get embeded script
          script = REXML::XPath.first(doc, "/#{prefix}interactive/#{prefix}script")
          model[:script] = script.text
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |seq|
        if ENV["PIONE_JOB_ID"]
          seq << :connect_webclient
        else
          # debug mode
          seq << :debug_mode
          seq << :print_result
        end
      end

      execution(:debug_mode) do |item|
        item.desc = "Launch a debug server"
        item.process do
          begin
            template = <<HTML
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>pione-interactive</title>
    <script>
      document.addEventListener("pione-interactive-result", function(event) {
        var msg = document.getElementById("message");

        // clear children
        while (msg.firstChild) {
          msg.removeChild(msg.firstChild);
        }

        // show the result
        var line1 = document.createElement("p");
        line1.textContent = "Result: " + event.result;
        msg.appendChild(line1);

        // server shutdown
        var req = new XMLHttpRequest();
        req.open("POST", "/shutdown", false);
        req.setRequestHeader("Content-Type", "text/plain");
        req.send(event.result);
        var line2 = document.createElement("p");
        line2.textContent = "Server has shutdowned. See your console, bye.";
        msg.appendChild(line2);
      });
    </script>
  </head>
  <body>
    <div>%s</div>
    <div id="message"></div>
    <script>window.onload = function() {%s};</script>
  </body>
</html>
HTML
            html = template % [model[:content], model[:script]]

            model[:debug_server] = WEBrick::HTTPServer.new(
              :Port => 8080, :Logger => WEBrick::Log.new($stderr)
            )

            # page handler on '/'
            model[:debug_server].mount_proc("/") do |req, res|
              res.body = html
              res['Content-Type'] = "text/html"
            end

            # shutdown handler on '/shutdown'
            model[:debug_server].mount_proc("/shutdown") do |req, res|
              model[:result] = req.body
              model[:debug_server].shutdown
            end

            # `Kernel.trap` can take multiple INT handlers
            trap("INT") { model[:debug_server].shutdown }

            # show the location
            $stderr.puts "See http://localhost:8080"

            # start the debug server
            model[:debug_server].start
          ensure
            if model[:debug_server]
              model[:debug_server].shutdown
            end
          end
        end
      end

      # Print a result string of interactive action to stdout.
      execution(:print_result) do |item|
        item.desc = "Print a result string."
        item.process do
          $stdout.print model[:result]
        end
      end
    end
  end
end