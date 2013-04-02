module Pione
  module Option
    # ChildProcessOption provides options for child process like
    # pione-task-worker or pione-tuple-space-receiver.
    module ChildProcessOption
      extend OptionInterface

      # --parent-front
      option('--parent-front=URI', 'set parent front URI') do |data, uri|
        data[:parent_front] = DRbObject.new_with_uri(uri)
      end

      # --no-parent
      option('--no-parent', 'turn on no parent mode') do
        data[:no_parent_mode] = true
      end
    end
  end
end
