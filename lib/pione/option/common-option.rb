module Pione
  module Option
    # CommonOption provides common options for pione commands.
    module CommonOption
      extend OptionInterface

      # --debug
      option('-d', '--debug', "turn on debug mode") do |data, name|
        Pione.debug_mode = true
      end

      # --show-communication
      option('--show-communication', "show object communication") do |data, show|
        Global.show_communication = true
      end

      # --color
      option('--[no-]color', 'turn on/off color mode') do |data, str|
        bool = nil
        bool = true if str == "true"
        bool = false if str == "false"
        if bool.nil?
          puts "invalid color option: %s" % bool
          exit
        end
        Terminal.color_mode = bool
      end
    end
  end
end
