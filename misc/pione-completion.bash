if type complete 1>/dev/null 2>&1;
then

  #
  # `pione` command
  #

  # set completion function
  complete -F _pione pione

  _pione() {
    # setup subcommans list
    local name2="${COMP_WORDS[1]}"
    local name3="${COMP_WORDS[2]}"

    case $name2 in
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
     COMPREPLY=($(compgen -W "action clean compile config diagnosis lang log package" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_action_subcommands() {
     COMPREPLY=($(compgen -W "exec list print" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_action_exec_options() {
    COMPREPLY=($(compgen -W "--color --debug --directory PATH --domain-dump" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_action_list_options() {
    COMPREPLY=($(compgen -W "--color --compact" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_action_print_options() {
    COMPREPLY=($(compgen -W "--color --debug --domain-dump" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_clean_options() {
    COMPREPLY=($(compgen -W "--debug --older --type NAME" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_compile_options() {
    COMPREPLY=($(compgen -W "--debug --editor --flow-name --package-name --tag" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_config_subcommands() {
     COMPREPLY=($(compgen -W "get list set unset" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_config_get_options() {
    COMPREPLY=($(compgen -W "--debug --file" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_config_list_options() {
    COMPREPLY=($(compgen -W "--debug --file" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_config_set_options() {
    COMPREPLY=($(compgen -W "--debug --file" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_config_unset_options() {
    COMPREPLY=($(compgen -W "--debug --file" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_diagnosis_subcommands() {
     COMPREPLY=($(compgen -W "notification" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_diagnosis_notification_options() {
    COMPREPLY=($(compgen -W "--color --debug --notification-receiver --notification-target --timeout --type" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_lang_subcommands() {
     COMPREPLY=($(compgen -W "check-syntax" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_lang_check-syntax_options() {
    COMPREPLY=($(compgen -W "--color --expr --file --model --parser --syntax" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_log_subcommands() {
     COMPREPLY=($(compgen -W "format list-id" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_log_format_options() {
    COMPREPLY=($(compgen -W "--agent-type --color --debug --format --log-id --trace-type" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_log_list-id_options() {
    COMPREPLY=($(compgen -W "--color --debug" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_package_subcommands() {
     COMPREPLY=($(compgen -W "add build show update" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_package_add_options() {
    COMPREPLY=($(compgen -W "--tag" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_package_build_options() {
    COMPREPLY=($(compgen -W "--color --debug --hash-id --output --tag" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_package_show_options() {
    COMPREPLY=($(compgen -W "--advanced --color --debug" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  _pione_package_update_options() {
    COMPREPLY=($(compgen -W "--color --debug --force" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  #
  # `pione-client` command
  #

  # set completion function
  complete -F _pione-client pione-client

  _pione-client() {
    # set option list
    _pione-client_options
  }

  _pione-client_options() {
    COMPREPLY=($(compgen -W "--color --communication-address --debug --dry-run --features --file-cache-method --file-sliding --input --notification-receiver --notification-target --output --params="{Var:1,...}" --parent-front --rehearse --request-task-worker --stand-alone --stream --task-worker-size --timeout" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  #
  # `pione-task-worker` command
  #

  # set completion function
  complete -F _pione-task-worker pione-task-worker

  _pione-task-worker() {
    # set option list
    _pione-task-worker_options
  }

  _pione-task-worker_options() {
    COMPREPLY=($(compgen -W "--color --communication-address --debug --features --file-cache-method --file-sliding --parent-front --tuple-space-id" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  #
  # `pione-task-worker-broker` command
  #

  # set completion function
  complete -F _pione-task-worker-broker pione-task-worker-broker

  _pione-task-worker-broker() {
    # set option list
    _pione-task-worker-broker_options
  }

  _pione-task-worker-broker_options() {
    COMPREPLY=($(compgen -W "--color --communication-address --debug --features --file-cache-method --file-sliding --task-worker-size" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  #
  # `pione-tuple-space-provider` command
  #

  # set completion function
  complete -F _pione-tuple-space-provider pione-tuple-space-provider

  _pione-tuple-space-provider() {
    # set option list
    _pione-tuple-space-provider_options
  }

  _pione-tuple-space-provider_options() {
    COMPREPLY=($(compgen -W "--color --communication-address --debug --notification-target --parent-front" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

  #
  # `pione-notification-listener` command
  #

  # set completion function
  complete -F _pione-notification-listener pione-notification-listener

  _pione-notification-listener() {
    # set option list
    _pione-notification-listener_options
  }

  _pione-notification-listener_options() {
    COMPREPLY=($(compgen -W "--color --communication-address --debug --notification-receiver" -- "${COMP_WORDS[COMP_CWORD]}"));
  }

fi
