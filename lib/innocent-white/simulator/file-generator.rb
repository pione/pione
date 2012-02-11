module InnocentWhite
  module Simulator
    module Agent
      class FileGenerator < InnocentWhite::Agent::Base
        def initialize(range, ext)
          super()
          @range = range
          @ext = ext
          @ts_server = nil
        end

        def data_tuple(basename)
          name = filename(basename)
          Tuple[:data].new(name: name, path:"input/#{name}", time: Time.now)
        end

        def filename(basename)
          "#{basename}.#{@ext}"
        end

        def run(server)
          @ts_server = server
          @range.to_a.each do |basename|
            tuple = data_tuple(basename)
            @ts_server.write(tuple)
          end
        end
      end
    end
  end
end
