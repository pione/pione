module InnocentWhite
  module UpdateCriteria
    # Update if not exist some ouputs.
    def self.not_exist_output?(inputs, outputs)
      outputs.any?{|output| output.empty? }
    end

    def self.exist_newer_input?(inputs, outputs)
      return false

      # get output oldest time
      output_oldest_time = nil
      outputs.flatten.each do |output|
        if output.time < output_oldest_time
          output_oldest_time = output.time
        end
      end

      # get input last time
      input_last_time = nil
      inputs.flatten.each do |input|
        if input.time > input_last_time
          input_last_time = input.time
        end
      end

      # criteria
      return output_oldest_time > input_last_time
    end

    def self.satisfy?(inputs, outputs)
      CRITERIAS.any?{|name| self.send(name, inputs, outputs)}
    end

    CRITERIAS = [ :not_exist_output?,
                  :exist_newer_input? ]
  end
end
