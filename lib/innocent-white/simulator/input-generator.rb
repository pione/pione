module InnocentWhite
  module Simulator
    module Agent
      class FileGenerator < InnocentWhite::Agent::Base
        def initialize(ts_server, range, ext)
          super(ts_server)
          @range = range
          @ext = ext
        end

        def data_tuple(basename)
          name = filename(basename)
          Tuple[:data].new(name: name, path:"input/#{name}", time: Time.now)
        end

        def filename(basename)
          "#{basename}.#{@ext}"
        end

        def run(server)
          @range.to_a.each do |basename|
            tuple = data_tuple(basename)
            @taple_space_server.write(tuple)
          end
          stop
        end
      end
    end
  end
end
