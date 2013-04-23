module Pione
  module Tuple
    # DataTuple is a class for input/output data.
    class DataTuple < BasicTuple
      attr_accessor :update_criteria
      attr_accessor :accept_nonexistence

      define_format [:data,
        # target domain
        [:domain, String],
        # data name
        [:name, Type.or(String, Model::DataExpr)],
        # data location
        [:location, Location::BasicLocation],
        # data created time
        [:time, Time]
      ]
    end
  end
end

