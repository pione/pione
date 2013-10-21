module Pione
  module Util
    class PNMLCompiler
      def initialize(src)
        @src = src
      end

      # Compile PNML file into PIONE document as a string.
      def compile
        doc = REXML::Document.new(@src.read)
        rule_table = make_rule_table(doc)
        io_table = make_io_table(doc)
        input_table = make_input_table(doc, rule_table, io_table)
        output_table = make_output_table(doc, rule_table, io_table)
        rules = make_flow_rules(rule_table, input_table, output_table)
        return textize_flow_rules(rules)
      end

      private

      # Make rule mapping table by collecting transitions and associating with its id and name.
      def make_rule_table(doc)
        rule_table = Hash.new
        REXML::XPath.each(doc, "/pnml/net/transition") do |elt|
          id = elt.attribute("id").value
          name = REXML::XPath.first(elt, "name/text").texts.map{|text| text.value}.join("")
          rule_table[id] = name
        end
        return rule_table
      end

      # Make input and output mapping table by collecting places and associating its id and name.
      def make_io_table(doc)
        io_table = Hash.new {|h, k| h[k] = []}
        REXML::XPath.each(doc, "/pnml/net/place") do |elt|
          id = elt.attribute("id").value
          name = REXML::XPath.first(elt, "name/text").texts.map{|text| text.value}.join("")
          io_table[id] << name
        end
        return io_table
      end

      # Make rule's input table by collecting arcs and associating its source and target.
      def make_input_table(doc, rule_table, io_table)
        input_table = Hash.new {|h, k| h[k] = []}
        REXML::XPath.each(doc, "/pnml/net/arc") do |elt|
          source = elt.attribute("source").value
          target = elt.attribute("target").value
          name = REXML::XPath.first(elt, "inscription/text").texts.map{|text| text.value}.join("")
          input_table[rule_table[target]] << io_table[source]
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
          output_table[rule_table[source]] << io_table[target]
        end
        return output_table
      end

      # Make flow rules from rule table, input table, and output table.
      def make_flow_rules(rule_table, input_table, output_table)
        rules = Array.new
        rule_table.each do |key, rule_name|
          inputs = input_table[rule_name]
          outputs = output_table[rule_name]
          rules << [rule_name, inputs, outputs]
        end
        return rules
      end

      FLOW_RULE_TEMPLATE = <<-RULE
        Rule %s
          %s
          %s
        Action
          cp {$I[1]} {$O[1]}
        End
      RULE

      # Textize flow rules.
      def textize_flow_rules(rules)
        rules.map do |rule|
          inputs = rule[1].map {|name| "input '%s'" % name}.join("\n  ")
          outputs = rule[2].map {|name| "output '%s'" % name}.join("\n  ")
          Indentation.cut(FLOW_RULE_TEMPLATE) % [rule[0], inputs, outputs]
        end.join("\n\n")
      end
    end
  end
end
