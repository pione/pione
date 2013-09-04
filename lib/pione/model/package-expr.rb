module Pione
  module Model
    # PackageExpr is an referential expression of PIONE package.
    class PackageExpr < Piece
      piece_type_name "PackageExpr"
      member :name
      member :package_id
      member :parent_id
      member :param, default: ParameterSetSequence.new

      def eval(env)
        # get package id
        _package_id = package_id ? package_id : env.find_package_id_by_package_name(name)
        # get definition
        definition = env.package_get(set(package_id: _package_id))
        # update package expression
        attr = {}
        attr[:package_id] = definition.package_id
        attr[:parent_id] = definition.parent_id
        attr[:param] = param.eval(env)
        set(attr)
      end
    end

    class PackageExprSequence < OrdinalSequence
      pione_type TypePackageExpr
      piece_class PackageExpr
    end

    #
    # pione methods
    #
    TypePackageExpr.instance_eval do
      # Set the edition name.
      define_pione_method("edition", [TypeString], TypePackageExpr) do |env, rec, name|
        rec.map {|piece| piece.set(edition: name)}
      end

      # Set the tag name.
      define_pione_method("tag", [TypeString], TypePackageExpr) do |env, rec, name|
        rec.map {|piece| piece.set(tag: name)}
      end

      # Set the state.
      define_pione_method("state", [TypeString], TypePackageExpr) do |env, rec, name|
        rec.map {|piece| piece.set(state: name)}
      end

      define_pione_method("param", [], TypeParameterSet) do |env, rec|
        rec.fold(ParameterSetSequence.new) do |seq, rec_piece|
          seq.set(pieces: seq.pieces + rec_piece.param.pieces)
        end
      end

      define_pione_method("param", [TypeParameterSet], TypePackageExpr) do |env, rec, other|
        rec.map2(other) do |rec_piece, other_piece|
          _param = rec_piece.param
          if _param.pieces.empty?
            rec_piece.set(param: other)
          else
            rec_piece.set(param: _param.map {|param_piece| param_piece.set(table: param_piece.table.merge(other_piece.table))})
          end
        end
      end

      # Assign the package id to the variable.
      define_deferred_pione_method("var", [TypeVariable], TypeVariable) do |env, rec, var|
        var.set(package_id: rec.pieces.first.package_id)
      end

      # Assign the package id to the rule expression.
      define_pione_method("rule", [TypeRuleExpr], TypeRuleExpr) do |env, rec, rule|
        RuleExprSequence.map2(rec, rule) {|rec_piece, rule_piece| rule_piece.set(package_id: rec_piece.package_id)}
      end
    end
  end
end
