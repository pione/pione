module Pione
  module Package
    # ScenarioReader is a reader for scenario location.
    class ScenarioReader
      class << self
        def read(location)
          new(location).read
        end
      end

      def initialize(location)
        @location = location
        @document_location = @location + "Scenario.pione"
        @info_location = @location + "pione-scenario.json"
      end

      def read
        if @document_location.mtime > @info_location.mtime
          # update the information file and make handler by it
          new_info = ScenarioScanner.scan(@location)
          return ScenarioHandler.new(@locaiton, new_info).tap {|handler| handler.write_info_file}
        else
          # make handler by informaiton file
          ScenarioHandler.new(@location, ScenarioInfo.read(@info_location))
        end
      end
    end
  end
end
