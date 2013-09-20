module Pione
  module Lang
    # DelegatableTable is a value table identified by two keys(package id and name).
    class DelegatableTable
      def initialize(parent, table=Hash.new {|h, k| h[k] = Hash.new})
        @parent = parent # parent delegatable table
        @table = table   # 2d table
      end

      # Return true if the name with the package id is bound.
      def bound?(package_id, name)
        @table[package_id][name] || (@parent ? @parent.bound?(package_id, name) : false)
      end

      # Find value of the reference recursively. We will raise
      # +CircularReferenceError+ if the reference is circular.
      def get(env, ref)
        history = [ref.package_id, ref.name]

        # detect reference loop
        if env.reference_history.include?(history)
          raise CircularReferenceError.new(ref)
        end

        # push package id and name to history
        _env = env.set(reference_history: env.reference_history + [history])

        # get the expression and evaluate it
        if expr = get_value(env, ref)
          evaluate_value(_env, expr)
        else
          raise UnboundError.new(ref)
        end
      end

      def get!(env, ref)
        get(env, ref)
      rescue UnboundError
        nil
      end

      # Get the value expression corresponding to the reference in the
      # table. This method is not circular.
      def get_value(env, ref)
        unless ref.package_id
          raise ArgumentError.new("package id is invalid: %s" % ref.inspect)
        end

        # when it is known reference
        if expr = @table[ref.package_id][ref.name]
          return expr
        end

        if bound?(ref.package_id, ref.name)
          # get value from parent table
          return @parent.get_value(env, ref) if @parent
        else
          # or find by parent package id
          if parent_id = env.find_parent_id(ref.package_id)
            return get_value(env, ref.set(package_id: parent_id))
          end
        end
      end

      # Update table with the name and value. We will raise +RebindError+ if the
      # reference is bound already.
      def set(ref, val)
        unless bound?(ref.package_id, ref.name)
          set!(ref, val)
        else
          raise RebindError.new(ref)
        end
      end

      # Update the table with the name and value. This method permits to
      # overwrite the value, so you can ignore +RebindError+.
      def set!(ref, val)
        @table[ref.package_id][ref.name] = val
      end

      # Return all reference in the table and the parent.
      def keys
        @table.keys.inject(@parent ? @parent.keys : []) do |res, k1|
          @table[k1].keys.inject(res) do |_res, k2|
            ref = make_reference(k1, k2)
            _res.include?(ref) ? _res : res << ref
          end
        end
      end

      def inspect
        if @parent
          "#%s(%s,%s)" % [self.class.name.split("::").last, @table, @parent.inspect]
        else
          "#%s(%s)" % [self.class.name.split("::").last, @table]
        end
      end

      def dumpable
        parent = @parent ? @parent.dumpable : nil
        table = Hash[*@table.to_a.flatten]
        self.class.new(parent, table)
      end
    end

    # VariableTable is a table for recording variables and values.
    class VariableTable < DelegatableTable
      # Evaluate table value simply.
      def evaluate_value(env, expr)
        expr.eval(env)
      end

      # Make a variable as a reference.
      def make_reference(package_id, name)
        Model::Variable.new(name, package_id)
      end
    end

    # RuleTable is a table for recording rule names and rule definitions.
    class RuleTable < DelegatableTable
      # Evaluate table value, but we get the referent recuirsively if the value
      # is a referential rule expression.
      def evaluate_value(env, expr)
        if expr.is_a?(Model::RuleExpr)
          definition = get(env, env.setup_package_id(expr))
          definition.set(param_sets: definition.param_sets.merge(expr.param_sets))
        else
          expr
        end
      end

      # Make a rule expression as a reference.
      def make_reference(package_id, name)
        Model::RuleExpr.new(name, package_id)
      end
    end

    # PackageTable is a table for pairs of child package id and parent package id.
    class PackageTable
      def initialize
        @table = Hash.new
      end

      def get(ref)
        if val = @table[ref.package_id]
          return val
        else
          raise UnboundError.new(ref)
        end
      end

      def set(ref, val)
        unless @table.has_key?(ref.package_id)
          @table[ref.package_id] = val
        else
          raise RebindError.new(ref)
        end
      end

      def inspect
        "#%s%s" % [self.class.name.split("::").last, @table]
      end
    end

    # Environment is a environment of language interpretation.
    class Environment < StructX
      immutable true

      # variable table
      member :variable_table, default: lambda {|env| VariableTable.new(nil)}
      # rule table
      member :rule_table, default: lambda {|env| RuleTable.new(nil)}
      # package table
      member :package_table, default: lambda {|env| PackageTable.new}
      # package ids
      member :package_ids, default: lambda { Array.new}
      # package id table: from package name to package id
      member :package_id_table, default: lambda { Hash.new }
      # current package id
      member :current_package_id
      # current definition
      member :current_definition
      # history of reference
      member :reference_history, default: lambda { Array.new }

      # Get the value of variable. We use current package id if it is implicit.
      def variable_get(ref)
        variable_table.get(self, setup_package_id(ref))
      end

      def variable_get!(ref)
        variable_table.get!(self, setup_package_id(ref))
      end

      # Set the value of variable.
      def variable_set(ref, val)
        _val = val.kind_of?(Model::Variable) ? setup_package_id(val) : val
        variable_table.set(setup_package_id(ref), val)
      end

      def variable_set!(ref, val)
        variable_table.set!(setup_package_id(ref), val)
      end

      # Get the definition of rule expression. We use current package id if it is implicit.
      def rule_get(ref)
        rule_table.get(self, setup_package_id(ref))
      end

      def rule_get!(ref)
        rule_table.get!(self, setup_package_id(ref))
      end

      # Get the expression of the reference.
      def rule_get_value(ref)
        if val = rule_table.get_value(self, setup_package_id(ref))
          return val
        else
          (raise UnboundError.new(ref))
        end
      end

      # Set the definition of rule expression.
      def rule_set(ref, val)
        rule_table.set(setup_package_id(ref), val)
      end

      # Get the definition of package.
      def package_get(ref)
        raise ArgumentError.new(ref.inspect) unless ref.package_id

        package_table.get(ref)
      end

      # Set the definition of package.
      def package_set(ref, val)
        raise ArgumentError.new(ref.inspect) unless ref.package_id

        package_table.set(ref, val)
      end

      # Make a temporary environment with the temporary informations and
      # evaluate the block in it. This is for evaluating declarations.
      def temp(temporary_info, &b)
        set(temporary_info).tap {|x| yield(x)}
        return nil
      end

      def find_package_id_by_package_name(package_name)
        package_id_table[package_name]
      end

      def find_parent_id(package_id)
        if package = package_get(Model::PackageExpr.new(package_id: package_id))
          package.parent_id
        end
      end

      # Create a new environment which tables are overlayed current tables.
      def layer
        self.class.new(
          variable_table: VariableTable.new(variable_table),
          rule_table: RuleTable.new(rule_table),
          package_table: package_table,
          package_ids: package_ids,
          current_package_id: current_package_id,
          current_definition: current_definition
        )
      end

      def merge(param_set)
        param_set.keys.each do |key|
          var = Model::Variable.new(name: key, package_id: current_package_id)
          val = param_set[key]
          variable_set(var, val)
        end
        return self
      end

      def add_package(package_name, parent_id=nil)
        # generate a new package id
        package_id = Util::PackageID.generate(self, package_name)
        # add package id table
        package_id_table[package_name] = package_id
        # make reference and definition
        ref = Model::PackageExpr.new(name: package_name, package_id: package_id)
        definition = Lang::PackageDefinition.new(package_id: package_id, parent_id: parent_id)
        # set it to package table
        package_set(ref, definition)
        # return package id
        return package_id
      end

      # Introduce new package in the environment.
      def setup_new_package(package_name, parent_id=nil)
        package_id = add_package(package_name, parent_id)
        # update current package id
        set(current_package_id: package_id)
      end

      def make_root_rule(param_set)
        # set $ROOT_PRARAM_SET
        variable_set(Model::Variable.new("ROOT_PARAM_SET"), param_set)
        # make root rule
        opt = {package_name: current_package_id, filename: "*system*"}
        Component::Document.parse(<<-PIONE, opt).eval(self)
           Rule Root
             input '*'.all or null
             output '*'.all
           Flow
             rule Main.param($ROOT_PARAM_SET)
           End
        PIONE
        rule_get(Model::RuleExpr.new("Root"))
      end

      # Set current package id to the reference if the package id is unknown.
      def setup_package_id(ref)
        return ref if ref.package_id

        # check current package id
        unless current_package_id
          raise Lang::EnvironmentError.new("we couldn't determine the package id: %s" % ref)
        end

        # create new reference with the package id
        ref.set(package_id: current_package_id)
      end

      # Return a new environment that we can dump. This is because deleagatable
      # tables use hashs with default proc, so it is not able to dump by using
      # +Marshal+.
      def dumpable
        set(variable_table: variable_table.dumpable, rule_table: rule_table.dumpable)
      end
    end
  end
end