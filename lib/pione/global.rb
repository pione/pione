module Pione
  module Global
    def self.set_item(name)
      define_method(name) do
        instance_variable_get("@%s" % name)
      end

      define_method("set_%s" % name) do |val|
        instance_variable_set("@%s" % name, val)
      end
    end

    set_item(:tuple_space_provider_uri)
  end

  extend Global
end
