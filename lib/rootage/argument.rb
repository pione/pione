module Rootage
  # `Argument` is an argument item for command.
  class Argument < Item
    # Normalization type.
    member :type
    # Name at heading in help.
    member :heading
    # The message to show if the argument is missing
    member :missing

    def validate(&b)
      self.validator = b
    end
  end

  module ArgumentCollection
    include CollectionInterface
    set_item_class Argument
  end

  class ArgumentDefinition < Sequence
    include CollectionInterface
    set_item_class Argument

    private

    # Parse the argument.
    #
    # @param cmd [Command]
    #   command object
    # @return [void]
    def execute_main(cmd)
      list.each_with_index do |item, i|
        if cmd.argv[i].nil?
          if item.missing
            raise ArgvError.new(item.missing)
          else
            raise ArgvError.new("The argument <%{name}> required." % {name: item.heading || item.name})
          end
        else
          cmd.model[item.key] = Normalizer.normalize(item.type, cmd.argv[i])
        end
      end
    end
  end
end
