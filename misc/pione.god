# -*- ruby -*-

DIR = File.join(File.dirname(__FILE__), "..")

# Watch `pione-task-worker-broker` command.
God.watch do |w|
  w.name = "pione-notification-listener"
  w.start = "bundle exec pione-notification-listener"
  w.log = File.join(DIR, "god-notification-listener.log")
  w.dir = DIR
  w.keepalive
end

# Watch `pione-task-worker-broker` command.
God.watch do |w|
  w.name = "pione-task-worker-broker"
  w.start = "bundle exec pione-task-worker-broker"
  w.log = File.join(DIR, "god-task-worker-broker.log")
  w.dir = DIR
  w.keepalive
end

