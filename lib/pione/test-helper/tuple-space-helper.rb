module Pione
  module TestHelper
    module TupleSpace
      # Create a customized tuple space.
      def self.create(context=nil)
        # make drb server and it's connection
        tuple_space = Pione::TupleSpace::TupleSpaceServer.new({}, false)

        # base location
        base_location = Pione::Location[Temppath.create]
        tuple_space.write(Pione::TupleSpace::BaseLocationTuple.new(base_location))

        context.set_tuple_space(tuple_space) if context

        return tuple_space
      end

      # Check exceptions in tuple space.
      def self.check_exceptions(tuple_space)
        exceptions = tuple_space.read_all(Pione::TupleSpace::ExceptionTuple.any)
        exceptions.each do |tuple|
          e = tuple.value
          Bacon::ErrorLog << "#{e.class}: #{e.message}\n"
          e.backtrace.each_with_index { |line, i| Bacon::ErrorLog << "\t#{line}\n" }
          Bacon::ErrorLog << "\n"
        end
        exceptions.should.be.empty
      end
    end
  end
end
