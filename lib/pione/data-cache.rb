module Pione
  class DataCache < PioneObject
    include TupleSpaceServerInterface
    include DRbUndumped

    PORT = 61150
    URI = "druby://localhost:61150"
    MAX_RETRY_NUMBER = 5

    attr_reader :cache_dir

    def initialize(cache_dir, tuple_space_server)
      set_tuple_space_server(tuple_space_server)
      @cache_dir = cache_dir
    end

    def get(uri)
      base_uri = read(Tuple[:base_uri])
      rel_path = uri - base_uri
      
    end

    def real_path(data_expr)
      
    end
  end
end
