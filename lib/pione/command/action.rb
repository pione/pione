module Pione
  module Command
    # `InitAction` is a set of actions for PIONE commands initialization.
    module InitAction
      extend Rootage::ActionCollection

      define(:front) do |item|
        item.desc = "Initialize a front server"

        item.assign(:front) do
          test(cmd.info[:front])

          cmd.info[:front].new(cmd)
        end
      end
    end

    module CommonAction
      extend Rootage::ActionCollection

      define(:load_domain_dump) do |item|
        item.desc = "Load a domain dump file"

        item.assign(:domain_dump) do
          test(model[:domain_dump_location])

          if model[:domain_dump_location]
            System::DomainDump.load(model[:domain_dump_location])
          else
            cmd.abort('Domain dump "%s" not found.' % model[:domain_dump_location].uri)
          end
        end
      end
    end

    module ProcessAction
      extend Rootage::ActionCollection

      define(:connect_parent) do |item|
        item.desc = "Setup parent process connection"

        item.process do
          test(cmd.option_definition.find_item(:parent_front).requisite)
          test(not(model.specified?(:parent_front)))
          raise System::PioneBug.new("%{cmd} needs --parent-front" % {cmd: cmd.name})
        end

        item.process do
          test(model[:parent_front])
          model[:parent_front].register_child(Process.pid, model[:front].uri)

          # delegate system logger
          Global.system_logger = Log::DelegatableLogger.new(model[:parent_front].system_logger)

          # start to watch parent process
          Thread.new do
            while true
              # PPID 1 means the parent process is dead
              if Process.ppid == 1 or Util.error?{model[:parent_front].ping}
                break cmd.terminate
              end
              sleep 1
            end
          end
        end

        item.exception(Front::ChildRegistrationError) do |e|
          cmd.terminate
        end
      end

      define(:disconnect_parent) do |item|
        item.desc = "Terminate parent process connection"

        item.process do
          test(model[:parent_front])

          # maybe parent process is dead in this timing
          Util.ignore_exception do
            model[:parent_front].unregister_child(Process.pid)
          end
        end
      end

      define(:terminate_children) do |item|
        item.desc = "Terminate child processes"

        item.process do
          Sys::ProcTable.ps.select {|ps|
            if ps.ppid == Process.pid
              Util.ignore_exception {Process.kill(:TERM, ps.pid)}
            end
          }

          # wait all children
          children = Process.waitall.map{|(pid, _)| pid}
          if not(children.empty?)
            arg = {name: cmd.name, pid: children.join(", ")}
            Log::Debug.system('"%{name}" has killed #%{pid}' % arg)
          end
        end
      end
    end
  end
end
