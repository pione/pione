if type compdef 1>/dev/null 2>&1;
then

  #
  # `pione` command
  #

  # set completion function
  compdef _pione pione

  _pione() {
    # setup subcommans list
    local name2="${words[2]}"
    local name3="${words[3]}"

    case $name2 in
      val) _pione_val_options;;
      action)
        case $name3 in
          exec) _pione_action_exec_options;;
          list) _pione_action_list_options;;
          print) _pione_action_print_options;;
          *) _pione_action_subcommands;;
        esac;;
      clean) _pione_clean_options;;
      compile) _pione_compile_options;;
      config)
        case $name3 in
          get) _pione_config_get_options;;
          list) _pione_config_list_options;;
          set) _pione_config_set_options;;
          unset) _pione_config_unset_options;;
          *) _pione_config_subcommands;;
        esac;;
      diagnosis)
        case $name3 in
          notification) _pione_diagnosis_notification_options;;
          *) _pione_diagnosis_subcommands;;
        esac;;
      lang)
        case $name3 in
          check-syntax) _pione_lang_check-syntax_options;;
          *) _pione_lang_subcommands;;
        esac;;
      log)
        case $name3 in
          format) _pione_log_format_options;;
          list-id) _pione_log_list-id_options;;
          *) _pione_log_subcommands;;
        esac;;
      package)
        case $name3 in
          add) _pione_package_add_options;;
          build) _pione_package_build_options;;
          show) _pione_package_show_options;;
          update) _pione_package_update_options;;
          *) _pione_package_subcommands;;
        esac;;
      *) _pione_subcommands;;
    esac
  }

  _pione_subcommands() {
     list=(val:"Get the value of the PIONE expression" action:"execute an action in literate action document" clean:"Remove PIONE's temporary files, cache, and etc" compile:"translate from PNML to PIONE document" config:"Configure PIONE global variables" diagnosis:"PIONE diagnosis tools" lang:"PIONE language utilities" log:"Log utilities" package:"PIONE package utility") _describe -t common-commands 'common commands' list;
  }

  _pione_val_options() {
    _arguments -s -S "--debug[Turn on debug mode about the type]" "--domain-dump[Import the domain dump file]" '*:file:_files' && return 0;
  }

  _pione_action_subcommands() {
     list=(exec:"Execute an action rule in literate action document" list:"List action names in document" print:"Print action contents") _describe -t common-commands 'common commands' list;
  }

  _pione_action_exec_options() {
    _arguments -s -S "--color[Turn on/off color mode]" "--debug[Turn on debug mode about the type]" "--directory PATH[execute in the PATH]" "--domain-dump[Load the domain dump file]" '*:file:_files' && return 0;
  }

  _pione_action_list_options() {
    _arguments -s -S "--color[Turn on/off color mode]" "--compact[one-line list]" '*:file:_files' && return 0;
  }

  _pione_action_print_options() {
    _arguments -s -S "--color[Turn on/off color mode]" "--debug[Turn on debug mode about the type]" "--domain-dump[Import the domain dump file]" '*:file:_files' && return 0;
  }

  _pione_clean_options() {
    _arguments -s -S "--debug[Turn on debug mode about the type]" "--older[remove file older than the date]" "--type NAME[remove only files of the type]" '*:file:_files' && return 0;
  }

  _pione_compile_options() {
    _arguments -s -S "--action[Set a literate action document]" "--debug[Turn on debug mode about the type]" "--editor[Set package editor]" "--flow-name[Set flow name]" "--package-name[Set package name]" "--tag[Set package tag]" '*:file:_files' && return 0;
  }

  _pione_config_subcommands() {
     list=(get:"Get a value of PIONE global variable" list:"List PIONE global variables" set:"Set a value of PIONE global variable" unset:"Unset a value of PIONE global variable") _describe -t common-commands 'common commands' list;
  }

  _pione_config_get_options() {
    _arguments -s -S "--debug[Turn on debug mode about the type]" "--file[path of config file]" '*:file:_files' && return 0;
  }

  _pione_config_list_options() {
    _arguments -s -S "--debug[Turn on debug mode about the type]" "--file[path of config file]" '*:file:_files' && return 0;
  }

  _pione_config_set_options() {
    _arguments -s -S "--debug[Turn on debug mode about the type]" "--file[path of config file]" '*:file:_files' && return 0;
  }

  _pione_config_unset_options() {
    _arguments -s -S "--debug[Turn on debug mode about the type]" "--file[path of config file]" '*:file:_files' && return 0;
  }

  _pione_diagnosis_subcommands() {
     list=(notification:"Diagnose notification settings") _describe -t common-commands 'common commands' list;
  }

  _pione_diagnosis_notification_options() {
    _arguments -s -S "--color[Turn on/off color mode]" "--debug[Turn on debug mode about the type]" "--notification-receiver[Receiver address that notifications are received at]" "--notification-target[Target address that notifications are sent to]" "--timeout[timeout after N second]" "--type[transmitter, receiver, or both]" '*:file:_files' && return 0;
  }

  _pione_lang_subcommands() {
     list=(check-syntax:"Interactive environment for PIONE language") _describe -t common-commands 'common commands' list;
  }

  _pione_lang_check-syntax_options() {
    _arguments -s -S "--color[Turn on/off color mode]" "--expr[PIONE expression]" "--file[PIONE document that is checked]" "--model[show internal model]" "--parser[Parser name]" "--syntax[show syntax tree]" '*:file:_files' && return 0;
  }

  _pione_log_subcommands() {
     list=(format:"Convert PIONE raw log into XES or other formats" list-id:"List log IDs") _describe -t common-commands 'common commands' list;
  }

  _pione_log_format_options() {
    _arguments -s -S "--agent-type[Output only the agent type: "task_worker", "input_generator", ...]" "--color[Turn on/off color mode]" "--debug[Turn on debug mode about the type]" "--format[Set format type]" "--log-id[Target log ID]" "--trace-type[Output only the trace type: "agent", "rule", or "task"]" '*:file:_files' && return 0;
  }

  _pione_log_list-id_options() {
    _arguments -s -S "--color[Turn on/off color mode]" "--debug[Turn on debug mode about the type]" '*:file:_files' && return 0;
  }

  _pione_package_subcommands() {
     list=(add:"Add the package to package database" build:"Build PIONE archive package" show:"Show the package informations" update:"Update the package to package database") _describe -t common-commands 'common commands' list;
  }

  _pione_package_add_options() {
    _arguments -s -S "--tag[Specify tag name]" '*:file:_files' && return 0;
  }

  _pione_package_build_options() {
    _arguments -s -S "--color[Turn on/off color mode]" "--debug[Turn on debug mode about the type]" "--hash-id[Specify git hash ID]" "--output[Output file or directory location]" "--tag[Specify tag name]" '*:file:_files' && return 0;
  }

  _pione_package_show_options() {
    _arguments -s -S "--advanced[show advanced parameters]" "--color[Turn on/off color mode]" "--debug[Turn on debug mode about the type]" '*:file:_files' && return 0;
  }

  _pione_package_update_options() {
    _arguments -s -S "--color[Turn on/off color mode]" "--debug[Turn on debug mode about the type]" "--force[Update pacakge information files]" '*:file:_files' && return 0;
  }

  #
  # `pione-client` command
  #

  # set completion function
  compdef _pione-client pione-client

  _pione-client() {
    # set option list
    _pione-client_options
  }

  _pione-client_options() {
    _arguments -s -S "--base[Set process base location]" "--client-ui[Type of the client's user interface]" "--color[Turn on/off color mode]" "--communication-address[Set the IP address for interprocess communication]" "--debug[Turn on debug mode about the type]" "--dry-run[Turn on dry run mode]" "--features[Set features]" "--file-cache-method[use NAME as a file cache method]" "--file-sliding[Enable/disable to slide files in file server]" "--input[Set input directory]" "--notification-receiver[Receiver address that notifications are received at]" "--notification-target[Target address that notifications are sent to]" "--params="{Var:1,...}"[Set user parameters]" "--parent-front[set parent front URI]" "--rehearse[rehearse the scenario]" "--request-from[URI that the client requested the job from]" "--request-task-worker[Set request number of task workers]" "--session-id[Session id of the job]" "--stand-alone[Turn on stand alone mode]" "--stream[Turn on/off stream mode]" "--task-worker-size[Set task worker size that this process creates]" "--timeout[timeout processing after SEC]" '*:file:_files' && return 0;
  }

  #
  # `pione-task-worker` command
  #

  # set completion function
  compdef _pione-task-worker pione-task-worker

  _pione-task-worker() {
    # set option list
    _pione-task-worker_options
  }

  _pione-task-worker_options() {
    _arguments -s -S "--color[Turn on/off color mode]" "--communication-address[Set the IP address for interprocess communication]" "--debug[Turn on debug mode about the type]" "--features[Set features]" "--file-cache-method[use NAME as a file cache method]" "--file-sliding[Enable/disable to slide files in file server]" "--parent-front[set parent front URI]" "--request-from[URI that the client requested the job from]" "--session-id[Session id of the job]" "--tuple-space-id[Tuple space ID that the worker joins]" '*:file:_files' && return 0;
  }

  #
  # `pione-task-worker-broker` command
  #

  # set completion function
  compdef _pione-task-worker-broker pione-task-worker-broker

  _pione-task-worker-broker() {
    # set option list
    _pione-task-worker-broker_options
  }

  _pione-task-worker-broker_options() {
    _arguments -s -S "--color[Turn on/off color mode]" "--communication-address[Set the IP address for interprocess communication]" "--debug[Turn on debug mode about the type]" "--features[Set features]" "--file-cache-method[use NAME as a file cache method]" "--file-sliding[Enable/disable to slide files in file server]" "--task-worker-size[Set task worker size that this process creates]" '*:file:_files' && return 0;
  }

  #
  # `pione-tuple-space-provider` command
  #

  # set completion function
  compdef _pione-tuple-space-provider pione-tuple-space-provider

  _pione-tuple-space-provider() {
    # set option list
    _pione-tuple-space-provider_options
  }

  _pione-tuple-space-provider_options() {
    _arguments -s -S "--color[Turn on/off color mode]" "--communication-address[Set the IP address for interprocess communication]" "--debug[Turn on debug mode about the type]" "--notification-target[Target address that notifications are sent to]" "--parent-front[set parent front URI]" '*:file:_files' && return 0;
  }

  #
  # `pione-notification-listener` command
  #

  # set completion function
  compdef _pione-notification-listener pione-notification-listener

  _pione-notification-listener() {
    # set option list
    _pione-notification-listener_options
  }

  _pione-notification-listener_options() {
    _arguments -s -S "--color[Turn on/off color mode]" "--communication-address[Set the IP address for interprocess communication]" "--debug[Turn on debug mode about the type]" "--notification-receiver[Receiver address that notifications are received at]" '*:file:_files' && return 0;
  }

fi
