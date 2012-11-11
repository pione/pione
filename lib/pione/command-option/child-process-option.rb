module Pione
  module CommandOption
    module ChildProcessOption
      extend OptionInterface

      # --parent-front
      define_option('--parent-front=URI', 'set parent front URI') do |uri|
        @parent_front = DRbObject.new_with_uri(uri)
      end

      # --no-parent
      define_option('--no-parent', 'turn on no parent mode') do
        @no_parent_mode = true
      end
    end
  end
end
