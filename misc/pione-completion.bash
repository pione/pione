if type complete 1>/dev/null 2>&1;
then

    #
    # `pione` command
    #

    complete -F _pione pione

    _pione() {
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
	    config) _pione_config_options;;
	    log) _pione_log_options;;
	    package)
		case $name3 in
		    add) _pione_package_add_options;;
		    build) _pione_package_build_options;;
		    show) _pione_package_show_options;;
		    update) _pione_package_update_options;;
		    *) _pione_package_subcommands;;
		esac;;
	    val) _pione_val_options;;
	    *) _pione_subcommands;;
	esac
    }

    _pione_subcommands() {
        COMPREPLY=($(compgen -W "action clean config log package val" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_action_subcommands() {
        COMPREPLY=($(compgen -W "exec list print" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_action_exec_options() {
        COMPREPLY=($(compgen -W "--[no-]color --debug[=TYPE] --directory PATH --domain" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_action_list_options() {
        COMPREPLY=($(compgen -W "--[no-]color --compact" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_action_print_options() {
        COMPREPLY=($(compgen -W "--[no-]color --domain" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_clean_options() {
        COMPREPLY=($(compgen -W "--debug[=TYPE] --older=DATE --type=NAME" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_config_options() {
        COMPREPLY=($(compgen -W "--debug[=TYPE] --file PATH --get NAME --list --set NAME VALUE --unset NAME VALUE" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_log_options() {
        COMPREPLY=($(compgen -W "--[no-]color --agent-activity[=TYPE] --debug[=TYPE] --format=(XES|JSON|HTML) --location=LOCATION --log-id=ID --rule-process --task-process" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_package_subcommands() {
        COMPREPLY=($(compgen -W "add build show update" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_package_add_options() {
        COMPREPLY=($(compgen -W "--tag=NAME" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_package_build_options() {
        COMPREPLY=($(compgen -W "--[no-]color --debug[=TYPE] --hash-id=HASH --output=LOCATION --tag=NAME" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_package_show_options() {
        COMPREPLY=($(compgen -W "--[no-]color --advanced --debug[=TYPE]" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_package_update_options() {
        COMPREPLY=($(compgen -W "--[no-]color --debug[=TYPE] --force" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    _pione_val_options() {
        COMPREPLY=($(compgen -W "--debug[=TYPE] --domain-info=LOCATION" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    #
    # `pione-client` command
    #

    complete -F _pione-client pione-client

    _pione-client() {
        _pione-client_options
    }

    _pione-client_options() {
        COMPREPLY=($(compgen -W "--[no-]color --communication-address=ADDRESS --debug[=TYPE] --dry-run --features=FEATURES --input=LOCATION --output=LOCATION --params="{Var:1,...}" --parent-front=URI --presence-notification-address=255.255.255.255:56000 --rehearse [SCENARIO] --relay=URI --request-task-worker=N --stand-alone --stream --task-worker=N --timeout SEC" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    #
    # `pione-task-worker` command
    #

    complete -F _pione-task-worker pione-task-worker

    _pione-task-worker() {
        _pione-task-worker_options
    }

    _pione-task-worker_options() {
        COMPREPLY=($(compgen -W "--[no-]color --communication-address=ADDRESS --debug[=TYPE] --features=FEATURES --parent-front=URI --tuple-space-id=UUID" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    #
    # `pione-broker` command
    #

    complete -F _pione-broker pione-broker

    _pione-broker() {
        _pione-broker_options
    }

    _pione-broker_options() {
        COMPREPLY=($(compgen -W "--[no-]color --communication-address=ADDRESS --daemon --debug[=TYPE] --features=FEATURES --task-worker=N" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    #
    # `pione-tuple-space-provider` command
    #

    complete -F _pione-tuple-space-provider pione-tuple-space-provider

    _pione-tuple-space-provider() {
        _pione-tuple-space-provider_options
    }

    _pione-tuple-space-provider_options() {
        COMPREPLY=($(compgen -W "--[no-]color --communication-address=ADDRESS --debug[=TYPE] --parent-front=URI --presence-notification-address=255.255.255.255:56000" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

    #
    # `pione-tuple-space-receiver` command
    #

    complete -F _pione-tuple-space-receiver pione-tuple-space-receiver

    _pione-tuple-space-receiver() {
        _pione-tuple-space-receiver_options
    }

    _pione-tuple-space-receiver_options() {
        COMPREPLY=($(compgen -W "--[no-]color --communication-address=ADDRESS --debug[=TYPE] --parent-front=URI --presence-port=PORT" -- "${COMP_WORDS[COMP_CWORD]}"));
    }

fi
