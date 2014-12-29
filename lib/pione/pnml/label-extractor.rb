module Pione
  module PNML
    # LabelExtractor extracts PIONE string from node label.
    module LabelExtractor
      class << self
        # Extract a rule expression.
        #
        # @param label [String]
        #   node label
        # @return [String]
        #   rule expression without modifier and comment
        def extract_rule_expr(label)
          extract_string(label, :rule_transition, :expr)
        end

        # Extract a data expression.
        #
        # @param label [String]
        #   node label
        # @return [String]
        #   data expression without modifier and comment
        def extract_data_expr(label)
          extract_string(label, :data_place, :expr)
        end

        # Extract a param set.
        #
        # @param name [String]
        #   node label
        # @return [String]
        #   parameter set string without modifier and comment
        def extract_param_set(label)
          extract_string(label, :expr_place, :expr)
        end

        # Extract a ticket.
        #
        # @param label [String]
        #   node label
        # @return [String]
        #   ticket string without modifier and comment
        def extract_ticket(label)
          extract_string(label, :expr_place, :expr)
        end

        # Extract a feature.
        #
        # @param label [String]
        #   node label
        # @return [String]
        #   feature string without modifier and comment
        def extract_feature(label)
          extract_string(label, :expr_place, :expr)
        end

        # Extract a param sentence.
        #
        # @param label [String]
        #   node label
        # @return [String]
        #   data expression without modifier and comment
        def extract_param_sentence(label)
          extract_string(label, :param_sentence, :param_sentence)
        end

        # Extract a feature sentence.
        #
        # @param label [String]
        #   node label
        # @return [String]
        #   feature sentence string without modifier and comment
        def extract_feature_sentence(label)
          extract_string(label, :feature_sentence, :feature_sentence)
        end

        # Extract a variable binding sentence.
        #
        # @param label [String]
        #   node label
        # @return [String]
        #   variable binding sentence string without modifier and comment
        def extract_variable_binding(label)
          extract_string(label, :variable_binding_sentence, :variable_binding_sentence)
        end

        # Extract priority.
        #
        # @param label [String]
        #   node label
        # @return [Integer]
        #   priority
        def extract_priority(label)
          matched = Parser.new.data_priority.parse(label)
          return matched[:priority].to_i
        rescue Parslet::ParseFailed
          return nil
        end

        # Extract key and value pairs from parameter set string.
        #
        # @param label [String]
        #   node label
        # @return [Hash]
        #   key and value pairs
        def extract_data_from_param_set(label)
          param_set = LabelExtractor.extract_param_set(label)

          parsed = Parser.new.expr_place.parse(param_set)
          tail_offset = parsed[:tail] ? parsed[:tail].offset : label.size

          keys = []
          values = []

          found = find_all_by_tree_names(parsed, [:key, :value, :separator, :footer])
          found.each_with_index do |item, index|
            if index % 3 == 0
              keys << item.to_s
            end

            if index % 3 == 1
              offset = find_head_character_position(item)
              separator_offset = found[index + 1] ? found[index + 1].offset : tail_offset
              values << label[offset, separator_offset - offset]
            end
          end

          return Hash[keys.zip(values)]
        end

        # Extract key and value pairs from parameter set string.
        #
        # @param label [String]
        #   node label
        # @return [Hash]
        #   key and value pairs
        def extract_data_from_param_sentence(label)
          param_sentence = LabelExtractor.extract_param_sentence(label)
          parsed = Parser.new.param_sentence.parse(param_sentence)

          # variable
          var = parsed[:param_sentence][:expr1][:expr][:variable][:name].to_s

          # value
          expr2 = parsed[:param_sentence][:expr2]
          expr2_offset = find_head_character_position(expr2)
          tail_offset = offset_of(parsed[:tail]) || label.size
          value = label[expr2_offset, tail_offset - expr2_offset]

          return {var => value}
        end

        private

        # Extract the string of expression.
        #
        # @param label [String]
        #   node label
        # @param paser_name [Symbol]
        #   parser name
        # @param tree_name [Symbol]
        #   tree name
        # @return [String]
        #   expression without modifier and comment
        def extract_string(label, parser_name, tree_name)
          return nil if label.nil?

          parsed = Parser.new.send(parser_name).parse(label)
          offset = find_head_character_position(parsed[tree_name])
          tail_offset = offset_of(find_parsed_element(parsed, :tail)) || label.size
          return label[offset, tail_offset - offset]
        end

        # Find position of head character of parsed tree.
        #
        # @param parsed [Hash]
        #   parsed tree
        # @return [Integer]
        #   position of head character or nil
        def find_head_character_position(parsed)
          return nil if parsed.nil?

          pos = nil
          parsed.values.each do |value|
            if value.kind_of?(Hash)
              if _pos = find_head_character_position(value)
                if pos.nil? or pos > _pos
                  pos = _pos
                end
              end
            else
              if value.kind_of?(Parslet::Slice) and (pos.nil? or pos > value.offset)
                pos = value.offset
              end
            end
          end
          return pos
        end

        def offset_of(value)
          if value.kind_of?(Parslet::Slice)
            value.offset
          end
        end

        # Find a parsed element by the name.
        #
        # @param parsed [Hash]
        #   parsed tree
        # @param name [Symbol]
        #   element name
        # @return [Object]
        #   parsed element
        def find_parsed_element(parsed, name)
          return nil if parsed.nil?

          parsed.each do |key, value|
            if key == name
              return value
            else
              if value.kind_of?(Hash)
                if elt = find_parsed_element(value, name)
                  return elt
                end
              end
            end
          end

          return nil
        end

        def find_all_by_tree_names(parsed, names)
          list = []
          return list if parsed.nil?

          parsed.each do |key, value|
            if names.include?(key)
              list << value
            else
              if value.kind_of?(Hash)
                list += find_all_by_tree_names(value, names)
              end

              if value.kind_of?(Array)
                value.each do |elt|
                  if elt.kind_of?(Hash)
                    list += find_all_by_tree_names(elt, names)
                  end
                end
              end
            end
          end

          return list
        end
      end
    end
  end
end
