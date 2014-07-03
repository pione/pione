require 'pione/global/interactive-variable'
require 'pione/front/interactive-front'

module Pione
  module Command
    class PioneInteractive < BasicCommand
      #
      # libraries
      #

      require 'rexml/document'

      #
      # informations
      #

      define(:toplevel, true)
      define(:name, "pione-interactive")
      define(:desc, "interactive action handler")
      define(:front, Front::InteractiveFront)

      #
      # arguments
      #

      # pione-interactive has no arguments

      #
      # options
      #

      option(:ui) do |item|
        item.type = :symbol_downcase
        item.long = "--ui"
        item.arg  = "NAME"
        item.desc = "User interface name"
      end

      option(:type) do |item|
        item.desc = "View type"
        item.type = :symbol_downcase
        item.long = "--type"
        item.arg  = "NAME"
      end

      option(:public) do |item|
        item.desc = "public directory for interactive operation pages"
        item.type = :location
        item.long = "--public"
        item.arg  = "DIR"
        item.init = "./public"
      end

      option(:definition) do |item|
        item.desc = "UI definition file"
        item.type = :location
        item.long = "--definition"
        item.arg  = "FILE"
      end

      option(:output) do |item|
        item.desc  = "Output file"
        item.type  = :location
        item.long  = "--output"
        item.short = "-o"
        item.arg   = "FILE"
      end

      option_post(:validate_ui) do |item|
        item.desc = "Validate UI name"

        item.process do
          test(model[:ui].nil?)
          raise Rootage::OptionError.new(cmd, "No UI name")
        end
      end

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |seq|
        seq << :session_id
        seq << :ui_definition
      end

      setup(:session_id) do |item|
        item.desc = "Setup session ID"
        item.process do
          if ENV["PIONE_SESSION_ID"]
            model[:session_id] = ENV["PIONE_SESSION_ID"]
            model[:request_from] = ENV["PIONE_REQUEST_FROM"]
          else
            # debug mode only
            require 'webrick'
          end
        end
      end

      setup(:interaction_id) do |item|
        item.desc = "Setup interaction ID"
        item.assign { Util::UUID.generate }
      end

      setup(:ui_definition) do |item|
        item.desc = "Extract informations from UI definition"
        item.process do
          test(model[:definition])

          fm = REXML::Formatters::Default.new

          # create a document
          doc = REXML::Document.new(model[:definition].read)

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
        seq << :render
        seq << :print_result
      end

      execution(:render) do |item|
        item.desc = "Render a widget"

        # this is called from webclient
        item.process do
          test(model[:session_id])
          test(model[:request_from])

          webclient = DRb::DRbObject.new_with_uri(model[:request_from])
          case model[:type]
          when :page
            result = webclient.request_interaction(model[:session_id], model[:interaction_id], :page, {:front => model[:front].uri.to_s})
          else # when :dialog
            result = webclient.request_interaction(model[:session_id], model[:interaction_id], :dialog, {:content => model[:content], :script => model[:script]})
          end
          model[:result] = result
        end

        # this is called from the exception of webclient
        item.process do
          test(not(model[:session_id] and model[:request_from]))
          test(model[:definition])

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

        # this is called from the exception of webclient
        item.process do
          test(not(model[:session_id] and model[:request_from]))
          test(model[:type] == :page)

          begin
            model[:debug_server] = WEBrick::HTTPServer.new(
              :Port => 8080, :Logger => WEBrick::Log.new($stderr)
            )

            # page handler on '/'
            model[:debug_server].mount("/", WEBrick::HTTPServlet::FileHandler, model[:public].path.to_s)

            # finish
            model[:debug_server].mount_proc("/finish") do |req, res|
              model[:result] = req.query["result"]
              model[:debug_server].shutdown
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
          if model[:output]
            model[:output].write model[:result]
          else
            $stdout.print model[:result]
          end
        end
      end
    end
  end
end
