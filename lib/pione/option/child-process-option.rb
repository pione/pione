module Pione
  module Option
    # ChildProcessOption provides options for child process like
    # pione-task-worker or pione-tuple-space-receiver.
    module ChildProcessOption
      extend OptionInterface

      define(:parent_front) do |item|
        item.long = '--parent-front=URI'
        item.desc = 'set parent front URI'
        item.action = proc do |option, uri|
          option[:parent_front] = DRbObject.new_with_uri(uri)
        end
      end

      define(:no_parent) do |item|
        item.long = '--no-parent'
        item.desc = 'turn on no parent mode'
        item.action = proc do |option|
          option[:no_parent_mode] = true
        end
      end
    end
  end
end
