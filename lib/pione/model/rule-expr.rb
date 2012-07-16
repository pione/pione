module Pione::Model
  class PackagePath < PioneModelObject
    def initialize(path)
      @path = path.split("/")
    end
  end

  # Rule representation in the flow element context.
  class RuleExpr < PioneModelObject
    attr_reader :package
    attr_reader :name
    attr_reader :sync_mode
    attr_reader :params

    # Create a rule expression.
    # @param [String] package pione package name
    # @param [String] name rule name
    def initialize(package, name, sync_mode=false, params=[])
      @package = package
      @name = name
      @sync_mode = sync_mode
      @params = params
    end

    def pione_model_type
      TypeRuleExpr
    end

    # Return true if sync mode.
    def sync_mode?
      @sync_mode
    end

    def sync(truth)
      return self.class.new(@package, @name, truth, @params)
    end

    def set_package(package)
      return self.class.new(package, @name, @sync_mode, @params)
    end

    def set_params(*params)
      return self.class.new(@package, @name, @sync_mode, params)
    end

    def eval(vtable=VariableTable.new)
      return self.class.new(@package, vtable.expand(@name), @sync_mode, @params)
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      return false unless @package = other.package
      return false unless @name == other.name
      return false unless sync_mode? == other.sync_mode?
      return false unless @params == other.params
      return true
    end

    alias :eql? :==

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

    define_pione_method("params",
                        [TypeList.new(TypeAny)],
                        TypeRuleExpr) do |rec, params|
      rec.set_params(params.value)
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      PioneString.new(rec.name)
    end
  end
end
