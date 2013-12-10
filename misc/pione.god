# -*- ruby -*-

DIR = File.join(File.dirname(__FILE__), "..")

# Watch `pione-task-worker-broker` command.
God.watch do |w|
  w.name = "pione-task-worker-broker"
  w.start = "bundle exec pione-task-worker-broker"
  w.log = File.join(DIR, "pione-god.log")
  w.dir = DIR
  w.keepalive
end

