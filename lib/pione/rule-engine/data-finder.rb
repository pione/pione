module Pione
  module RuleEngine
    # DataFinder finds data tuples from tuple space server.
    class DataFinder
      include TupleSpace::TupleSpaceInterface

      # Creates a new finder.
      def initialize(space, domain_id)
        set_tuple_space(space)
        @domain_id = domain_id
      end

      # Find data tuple combinations from tuple space server. This method calls
      # the block when the combination found.
      def find(type, conditions, env, &b)
        find_next(type, 1, conditions, env, [], &b)
      end

      private

      # Find input tuple combinatioins recursively.
      def find_next(type, index, conditions, env, combination, &b)
        # call block when we reach the recuirsion end
        return yield(env, combination) if conditions.empty?

        # expand variables and compile to regular expression
        head = conditions.first.eval(env)
        tail = conditions.drop(1)

        # find data tuples by head condition from tuple space server
        tuples = find_tuples_by_condition(head)

        # no tuples
        if tuples.empty?
          if head.accept_nonexistence?
            # accept noexistance data, find next tuples
            return find_next(type, index+1, tail, env.layer, combination + [[]], &b)
          else
            return # failed to find tuples
          end
        end

        # make combination results
        case head.distribution
        when :all
          _env = make_io_variables(type, index, :all, head, env, tuples)
          find_next(type, index+1, tail, _env, combination + [tuples], &b)
        when :each
          tuples.each do |tuple|
            _env = make_io_variables(type, index, :each, head, env, [tuple])
            find_next(type, index+1, tail, _env, combination + [[tuple]], &b)
          end
        end
      end

      # Find all matched data tuples by the rule expression condition from tuple space.
      def find_tuples_by_condition(condition)
        return read_all(Tuple[:data].new(name: condition, domain: @domain_id))
      end

      # Make input/output variables by data expression with all distribution.
      def make_io_variables(type, index, distribution, condition, env, tuples)
        _env = env.layer
        asterisk = []

        # variable and value
        var = Lang::Variable.new(type == :input ? "I" : "O")
        val = env.variable_get!(var) || Lang::KeyedSequence.new

        # update value
        _val = tuples.inject(val) do |_val, tuple|
          # matched data
          md = condition.match(tuple.name).to_a
          asterisk << md[1]

          # make a date expression
          data = Lang::DataExpr.new(pattern: tuple.name, location: tuple.location, matched_data: md)

          # update value
          _val.put(Lang::IntegerSequence.of(index), Lang::DataExprSequence.of(data))
        end
        _env.variable_set!(var, _val)

        # set special variable if index equals 1
        if type == :input && index == 1
          strs = asterisk.map{|str| Lang::PioneString.new(str)}
          _env.variable_set(
            Lang::Variable.new("*"),
            Lang::StringSequence.new(strs).set(distribution: distribution)
          )
        end

        return _env
      end
    end
  end
end
