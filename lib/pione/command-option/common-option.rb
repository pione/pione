module Pione
  module CommandOption
    module CommonOption
      extend OptionInterface

      # --debug
      define_option('-d', '--debug', "turn on debug mode") do |name|
        Pione.debug_mode = true
      end

      # --show-communication
      define_option('--show-communication', "show object communication") do |show|
        Global.show_communication = true
      end

      # --color
      define_option('--[no-]color', 'turn on/off color mode') do |str|
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
