require 'innocent-white/common'
require 'innocent-white/rule'
require 'innocent-white/agent/input-generator'
require 'innocent-white/agent/task-worker'
require 'innocent-white/agent/rule-provider'


include InnocentWhite

# get script dirname
$dir = File.dirname(File.expand_path(__FILE__))

# base uri
uri = "local:#{Dir.mktmpdir('innocent-white-')}/"

# make drb server and it's connection
$tuple_space_server = TupleSpaceServer.new(task_worker_resource: 1, base_uri: uri)

# read process document
$doc = Document.load(File.join($dir,'Sum.iw'))

# start rule provider
rule_loader = Agent[:rule_provider].start($tuple_space_server)
rule_loader.read_document($doc)
$tuple_space_server.write(Tuple[:process_info].new('sum', 'Sum'))

# start input generators
gen = Agent[:input_generator].start_by_dir($tuple_space_server, File.join($dir, "input"))
gen.wait_till(:terminated)

# add workers
Agent[:task_worker].start($tuple_space_server)

# execute
root = Rule::RootRule.new(RuleExpr.new('Main'))
handler = root.make_handler($tuple_space_server)

InnocentWhite.debug_mode do
  outputs = handler.execute
  p outputs
end
