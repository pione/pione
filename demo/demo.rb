require 'pione'
require 'sinatra'

#
# config
#

set :port, Global.relay_port
set :public_folder, File.dirname(__FILE__) + '/public'
enable :sessions

#
# utility functions
#

# stop client process
def stop_client_process(session)
  if client_address = session['client-address']
    client = DRbObject.new_with_uri(client_address)
    begin
      timeout(1) {client.terminate}
    rescue
      # ignore
    end
  end
end

$client_watcher = {}
$client_watcher_lock = Mutex.new

# start client process
def call_client_process(session, document_path, params, output, input)
  pione_client_name = Util.generate_uuid
  args = ["pione-client", document_path]
  args << "--name" << pione_client_name
  args << "--task-worker" << "0"
  args << "--params" << params if params
  args << "--output" << output if output
  args << "--input" << input if input
  pid = Process.spawn(*args)
  thread = Process.detach(pid)
  $client_watcher_lock.synchronize do
    $client_watcher[session["uuid"]] = thread
  end
  sleep 1
  ### find the client
  address = nil
  # avoid connection trouble
  DRb::DRbConn.clear_table
  Global.client_front_port_range.each do |port|
    begin
      address = "druby://%s:%s" % [Global.my_ip_address, port]
      client = DRbObject.new_with_uri(address)
      if client.name == pione_client_name
        session["base-uri"] = client.tuple_space_server.base_uri.to_s
        break
      end
    rescue
      address = nil
    end
  end
  return address
end

# check client process
def check_client_process(session)
  $client_watcher_lock.synchronize do
    return unless $client_watcher[session["uuid"]]
    if not($client_watcher[session["uuid"]].alive?)
      session['process-status'] = :finished
    end
  end
end

#
# common
#

before do
  check_client_process(session)
  session['uuid'] ||= Pione::Util.generate_uuid
end

#
# main page
#

get '/' do
  send_file File.join(File.dirname(__FILE__), 'public', 'index.html')
end

#
# process request handler
#

post '/process' do
  document_path = nil
  input = nil
  session['document'] = params[:document]
  case params[:document]
  when "Fib"
    document_path = "example/Fib/Fib.pione"
  when "CountChar"
    document_path = "example/CountChar/CountChar.pione"
    input = "example/CountChar/text"
  when "SingleParticlesWithRef"
    document_path = "example/SingleParticlesWithRef/SingleParticlesWithRef.pione"
    input = "example/SingleParticlesWithRef/data"
  else
    session['process-status'] = :error
    session['pione-error-message'] = "No document"
    return
  end
  session['input'] = true if input
  parameters = params[:parameters]
  parameters = nil if parameters == ""
  output = params[:output]

  # stop if client exists already
  stop_client_process(session)

  # start client
  if session['client-address'] = call_client_process(session, document_path, parameters, output, input)
    session['process-status'] = :processing
  else
    session['process-status'] = :connection_failure
  end
  return
end

#
# process status
#

get '/process_status' do
  session['process-status'] ? session['process-status'].to_s : "nil"
end

#
# info
#

get '/info' do
  begin
    process_status_message = make_process_status_message
    tuple_space_status = make_tuple_space_status
    task_worker_status = make_task_worker_status
    inputs = make_inputs
    outputs = make_outputs
    { "processStatusMessage" => process_status_message,
      "tupleSpaceStatus" => tuple_space_status,
      "taskWorkerStatus" => task_worker_status,
      "inputs" => inputs,
      "outputs" => outputs
    }.to_json
  rescue Exception => e
    ErrorReport.print(e)
    {}.to_json
  end
end

def make_process_status_message
  case session['process-status']
  when :processing
    'Processing %s...' % session[:document]
  when :connection_failure
    'Failed to connect client process'
  when :finished
    'Finished'
  when :error
    session['pione-error-message']
  else
    'No Process'
  end
end

def current_tuple_space_status
  { "task"     => session["task-size"    ],
    "working"  => session["working-size" ],
    "finished" => session["finished-size"],
    "data"     => session["data-size"    ] }
end

def unknown_tuple_space_status
  { "task"     => "unknown",
    "working"  => "unknown",
    "finished" => "unknown",
    "data"     => "unknown" }
end

def initial_tuple_space_status
  {"task" => 0, "working" => 0, "finished" => 0, "data" => 0}
end

def make_tuple_space_status
  case session['process-status']
  when :processing
    if client_address = session['client-address']
      client = DRbObject.new_with_uri(client_address)
      begin
        session["task-size"] = client.tuple_space_server.task_size
        session["working-size"] = client.tuple_space_server.working_size
        session["finished-size"] = client.tuple_space_server.finished_size
        session["data-size"] = client.tuple_space_server.data_size
        return current_tuple_space_status
      rescue
        # ignore
      end
    end
  when :finished
    return current_tuple_space_status
  else
    return initial_tuple_space_status
  end

  return unknown_tuple_space_status
end

def make_task_worker_status
  if session['process-status'] == :processing
    if client_address = session['client-address']
      client = DRbObject.new_with_uri(client_address)
      begin
        foregrounds = client.tuple_space_server.read_all(Tuple[:foreground].any)
        return foregrounds.map{|t| t.digest}
      rescue
        # ignore
      end
    end
  end

  return []
end

def make_inputs
  if session['input'] and base_uri = session['base-uri']
    input_uri = URI.parse(session["base-uri"]) + "input/"
    return Resource[input_uri].entries.map{|res| res.basename}
  else
    return []
  end
end

def make_outputs
  if base_uri = session['base-uri']
    return Resource[base_uri].entries.select do |res|
      res.basename[0] != "."
    end.map {|res| res.basename}
  else
    return []
  end
end

#
# clean
#

get '/clean' do
  stop_client_process(session)
  FileUtils.remove_entry_secure("output", true)
  session["task-size"] = 0
  session["working-size"] = 0
  session["finished-size"] = 0
  session["data-size"] = 0
  session["document"] = nil
  session["process-status"] = nil
  session["process-status-message"] = "Cleaned"
  session["client-address"] = nil
  session["input"] = nil
  session["uuid"] = nil
  session["base-uri"] = nil
  return
end

