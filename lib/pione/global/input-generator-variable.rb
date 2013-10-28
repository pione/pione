module Pione
  module Global
    # This is a timespan(sec) that input generator agent checks new inputs in
    # stream mode.
    define_external_item(:input_generator_stream_check_timespan) do |item|
      item.desc = "stream check timespan(sec) for input generator"
      item.init = 3
    end
  end
end
