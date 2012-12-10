module Pione
  module Tuple
    # DataTuple is a class for input/output data.
    class DataTuple < BasicTuple
      define_format [:data,
        # target domain
        [:domain, String],
        # data name
        [:name, Type.or(String, Model::DataExpr)],
        # resource location
        [:uri, String],
        # data created time
        [:time, Time]
      ]
    end
  end
end

