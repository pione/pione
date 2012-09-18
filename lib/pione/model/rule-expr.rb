module Pione::Model
  # Rule representation in the flow element context.
  class RuleExpr < PioneModelObject
    set_pione_model_type TypeRuleExpr

    attr_reader :package
    attr_reader :name
    attr_reader :sync_mode
    attr_reader :params

    # Create a rule expression.
    # @param [String] package pione package name
    # @param [String] name rule name
    # @param [Parameters] params parameters
    def initialize(package, name, sync_mode=false, params=Parameters.empty)
      @package = package
      @name = name
      @sync_mode = sync_mode
      @params = params
      super()
    end

    # Returns rule path form.
    # @return [String]
    #   rule path string
    def path
      "&%s:%s" % [@package.name, @name]
    end

    # FIXME
    def rule_path
      raise UnboundVariableError.new(self) if @package.include_variable?
      "&%s:%s" % [@package.name, @name]
    end

    # @api private
    def task_id_string
      "RuleExpr<%s,#{@name}>" % [@package.task_id_string]
    end

    # @api private
    def textize
      "rule_expr(%s,\"%s\")" % [@package.textize, @name]
    end

    # Sets a package name and returns a new expression.
    # @param [String] package
    #   package name
    # @return [RuleExpr]
    #   new rule expression with the package name
    def set_package(package)
      return self.class.new(package, @name, @sync_mode, @params)
    end

    # Sets parameters and returns a new expression.
    # @param [Parameters] params
    #   parameters
    # @return [RuleExpr]
    #   new rule expression with the parameters
    def set_params(params)
      return self.class.new(@package, @name, @sync_mode, params)
    end

    # Evaluates the object with the variable table.
    # @param [VariableTable] vtable
    #   variable table for evaluation
    # @return [PioneModelObject]
    #   evaluation result
    def eval(vtable)
      return self.class.new(
        @package.eval(vtable),
        @name,
        @sync_mode,
        @params.eval(vtable)
      )
    end

    # Returns true if the package or parameters include variables.
    # @return [Boolean]
    #   true if the package or parameters include variables
    def include_variable?
      @package.include_variable? or @params.include_variable?
    end

    # @api private
    def ==(other)
      return false unless other.kind_of?(self.class)
      return false unless @package = other.package
      return false unless @name == other.name
      return false unless sync_mode? == other.sync_mode?
      return false unless @params == other.params
      return true
    end

    # @api private
    alias :eql? :"=="

    # @api private
    def hash
      @package.hash + @name.hash + @params.hash + @sync_mode.hash
    end
  end

  TypeRuleExpr.instance_eval do
    define_pione_method("==", [TypeRuleExpr], TypeBoolean) do |rec, other|
      PioneBoolean.new(
        rec.package == other.package &&
        rec.name == other.name &&
        rec.sync_mode? == other.sync_mode? &&
        rec.params == other.params)
    end

    define_pione_method("!=", [TypeRuleExpr], TypeBoolean) do |rec, other|
      PioneBoolean.not(rec.call_pione_method("==", other))
    end

    define_pione_method("sync", [TypeBoolean], TypeRuleExpr) do |rec, b|
      rec.sync(b.value)
    end

    define_pione_method("params", [TypeParameters], TypeRuleExpr) do |rec, params|
      rec.set_params(params)
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      PioneString.new(rec.name)
    end
  end
end
