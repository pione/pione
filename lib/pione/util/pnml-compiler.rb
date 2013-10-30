module Pione
  module Util
    class PNMLCompiler
      def initialize(src, name, editor, tag)
        @src = src
        @name = name
        @editor = editor
        @tag = tag
      end

      # Compile PNML file into PIONE document as a string.
      def compile
        doc = REXML::Document.new(@src.read)
        rule_table = make_rule_table(doc)
        io_table = make_io_table(doc)
        input_table = make_input_table(doc, rule_table, io_table)
        output_table = make_output_table(doc, rule_table, io_table)

        annotations = []
        if @name
          annotations << ".@ PackageName :: \"%s\"" % @name
          annotations << ".@ Editor :: \"%s\"" % @editor if @editor
          annotations << ".@ Tag :: \"%s\"" % @tag if @tag
        end

        main_rule = textize_main_rule(*make_main_rule(rule_table, input_table, output_table))
        other_rules = textize_flow_rules(make_flow_rules(rule_table, input_table, output_table))

        [*annotations, "", main_rule, *other_rules].join("\n")
      end

      private

      # Make rule mapping table by collecting transitions and associating with its id and name.
      def make_rule_table(doc)
        rule_table = Hash.new
        REXML::XPath.each(doc, "/pnml/net/transition") do |elt|
          # transition id
          id = elt.attribute("id").value
          # transition name
          name = REXML::XPath.first(elt, "name/text").texts.map{|text| text.value}.join("")
          # rule table (id -> name)
          rule_table[id] = name
        end
        return rule_table
      end

      # Make input and output mapping table by collecting places and associating its id and name.
      def make_io_table(doc)
        io_table = Hash.new {|h, k| h[k] = []}
        REXML::XPath.each(doc, "/pnml/net/place") do |elt|
          # place id
          id = elt.attribute("id").value
          # place name
          name = REXML::XPath.first(elt, "name/text").texts.map{|text| text.value}.join("")
          # palce table (id -> names)
          io_table[id] << name
        end
        return io_table
      end

      # Make rule's input table by collecting arcs and associating its source and target.
      def make_input_table(doc, rule_table, io_table)
        input_table = Hash.new {|h, k| h[k] = []}
        REXML::XPath.each(doc, "/pnml/net/arc") do |elt|
          source = elt.attribute("source").value # source place(data) id
          target = elt.attribute("target").value # target transition(rule) id
          if rule_table.has_key?(target)
            name = REXML::XPath.first(elt, "inscription/text").texts.map{|text| text.value}.join("")
            input_table[rule_table[target]] += io_table[source]
          end
        end
        return input_table
      end

      # Make rule's output table by collecting arcs and associating its source and target.
      def make_output_table(doc, rule_table, io_table)
        output_table = Hash.new {|h, k| h[k] = []}
        REXML::XPath.each(doc, "/pnml/net/arc") do |elt|
          source = elt.attribute("source").value
          target = elt.attribute("target").value
          name = REXML::XPath.first(elt, "inscription/text").texts.map{|text| text.value}.join("")
          output_table[rule_table[source]] += io_table[target]
        end
        return output_table
      end

      # Make a main rule.
      def make_main_rule(rule_table, input_table, output_table)
        inputs = find_main_inputs(input_table, output_table)
        outputs = find_main_outputs(output_table)
        constituents = find_constituents(rule_table)
        return [inputs, outputs, constituents]
      end

      def find_main_inputs(input_table, output_table)
        input_table.values.each_with_object([]) do |names, main_inputs|
          inputs = names.select do |name|
            not(output_table.values.flatten.include?(name))
          end
          main_inputs.concat(inputs)
        end
      end

      def find_main_outputs(output_table)
        output_table.values.each_with_object([]) do |names, main_outputs|
          main_outputs.concat(names.select{|name| main_output?(name)})
        end
      end

      def find_constituents(rule_table)
        rule_table.values.compact.sort
      end

      MAIN_RULE_TEMPLATE = <<-RULE
        Rule Main
          %s
        Flow
          %s
        End
      RULE

      def textize_main_rule(inputs, outputs, constituents)
        i = inputs.map {|name| "input %s" % normalize_data_name(name)}
        o = outputs.map {|name| "output %s" % normalize_data_name(name)}
        conds = (i + o).join("\n  ")
        rules = constituents.map {|c| "rule %s" % c}.join("\n  ")
        Indentation.cut(MAIN_RULE_TEMPLATE) % [conds, rules]
      end

      # Make flow rules from rule table, input table, and output table.
      def make_flow_rules(rule_table, input_table, output_table)
        rules = Array.new
        rule_table.each do |key, rule_name|
          inputs = input_table[rule_name]
          outputs = output_table[rule_name]
          rules << [rule_name, inputs, outputs]
        end
        return rules.sort {|a, b| a.first <=> b.first}
      end

      FLOW_RULE_TEMPLATE = <<-RULE
        Rule %s
          %s
          %s
        End
      RULE

      # Textize flow rules.
      def textize_flow_rules(rules)
        rules.map do |rule|
          inputs = rule[1].map {|name| "input %s" % normalize_data_name(name)}.join("\n  ")
          outputs = rule[2].map {|name| "output %s.touch" % normalize_data_name(name)}.join("\n  ")
          Indentation.cut(FLOW_RULE_TEMPLATE) % [rule[0], inputs, outputs]
        end
      end

      def main_output?(name)
        name[0] == ">"
      end

      # Normalize the data name.
      def normalize_data_name(name)
        main_output?(name) ? name[1..-1] : name
      end
    end
  end
end
