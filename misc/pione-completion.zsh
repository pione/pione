if type compdef 1>/dev/null 2>&1;
then

    #
    # `pione` command
    #

    compdef _pione pione

    _pione() {
	local name2="${words[2]}"
	local name3="${words[3]}"

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
	    diagnosis)
		case $name3 in
		    notification) _pione_diagnosis_notification_options;;
		    *) _pione_diagnosis_subcommands;;
		esac;;
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
        list=(action:"execute an action in literate action document" clean:"remove PIONE's temporary files, cache, and etc." config:"config PIONE global variables" diagnosis:"PIONE diagnosis tools" log:"View and convert PIONE log." package:"PIONE package utility." val:"Get the evaluation result value of the PIONE expression.") _describe -t common-commands 'common commands' list;
    }

    _pione_action_subcommands() {
        list=(exec:"execute an action in literate action document" list:"list action names in document" print:"print action contents") _describe -t common-commands 'common commands' list;
    }

    _pione_action_exec_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--directory PATH[execute in the PATH]" "--domain[use the domain information file]" '*:file:_files' && return 0;
    }

    _pione_action_list_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--compact[one line list]" '*:file:_files' && return 0;
    }

    _pione_action_print_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--domain[use the domain information file]" '*:file:_files' && return 0;
    }

    _pione_clean_options() {
        _arguments -s -S "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--older=DATE[remove file older than the date]" "--type=NAME[remove only files of the type]" '*:file:_files' && return 0;
    }

    _pione_config_options() {
        _arguments -s -S "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--file PATH[config file path]" "--get NAME[get the item value]" "--list[list all]" "--set NAME VALUE[set the item]" "--unset NAME VALUE[set the item]" '*:file:_files' && return 0;
    }

    _pione_diagnosis_subcommands() {
        list=(notification:"a diagnosis tool for notification") _describe -t common-commands 'common commands' list;
    }

    _pione_diagnosis_notification_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--notification-receiver ADDR[receiver address that notifications are received at]" "--notification-target ADDR[target address that notifications are sent to]" "--timeout N[timeout after N second]" "--type NAME[sender, receiver, or both]" '*:file:_files' && return 0;
    }

    _pione_log_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--agent-activity\[=TYPE\][output only agent activity log]" "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--format=(XES|JSON|HTML)[set format type]" "--location=LOCATION[set log location of PIONE process]" "--log-id=ID[target log id]" "--rule-process[generate rule process log]" "--task-process[generate task process log]" '*:file:_files' && return 0;
    }

    _pione_package_subcommands() {
        list=(add:"add the package to package database" build:"build PIONE archive package" show:"show the package informations" update:"update the package to package database") _describe -t common-commands 'common commands' list;
    }

    _pione_package_add_options() {
        _arguments -s -S "--tag=NAME[specify tag name]" '*:file:_files' && return 0;
    }

    _pione_package_build_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--hash-id=HASH[specify git hash id]" "--output=LOCATION[output file or directory location]" "--tag=NAME[specify tag name]" '*:file:_files' && return 0;
    }

    _pione_package_show_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--advanced[show advanced parameters]" "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" '*:file:_files' && return 0;
    }

    _pione_package_update_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--force[update pacakge info files]" '*:file:_files' && return 0;
    }

    _pione_val_options() {
        _arguments -s -S "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--domain-info=LOCATION[location of Domain info file]" '*:file:_files' && return 0;
    }

    #
    # `pione-client` command
    #

    compdef _pione-client pione-client

    _pione-client() {
        _pione-client_options
    }

    _pione-client_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--communication-address=ADDRESS[set IP address for interprocess communication]" "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--dry-run[turn on dry run mode]" "--features=FEATURES[set features]" "--input=LOCATION[set input directory]" "--notification-address=ADDRESS[set the address for sending notification packet]" "--output=LOCATION[set output directory]" "--params="{Var:1,...}"[set user parameters]" "--parent-front=URI[set parent front URI]" "--rehearse \[SCENARIO\][rehearse the scenario]" "--relay=URI[turn on relay mode and set relay address]" "--request-task-worker=N[set request number of task workers]" "--stand-alone[turn on stand alone mode]" "--stream[turn on stream mode]" "--task-worker=N[set task worker number that this process creates]" "--timeout SEC[timeout processing after SEC]" '*:file:_files' && return 0;
    }

    #
    # `pione-task-worker` command
    #

    compdef _pione-task-worker pione-task-worker

    _pione-task-worker() {
        _pione-task-worker_options
    }

    _pione-task-worker_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--communication-address=ADDRESS[set IP address for interprocess communication]" "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--features=FEATURES[set features]" "--parent-front=URI[set parent front URI]" "--tuple-space-id=UUID[tuple space id that the worker joins]" '*:file:_files' && return 0;
    }

    #
    # `pione-task-worker-broker` command
    #

    compdef _pione-task-worker-broker pione-task-worker-broker

    _pione-task-worker-broker() {
        _pione-task-worker-broker_options
    }

    _pione-task-worker-broker_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--communication-address=ADDRESS[set IP address for interprocess communication]" "--daemon[turn on daemon mode]" "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--features=FEATURES[set features]" "--task-worker=N[set task worker number that this process creates]" '*:file:_files' && return 0;
    }

    #
    # `pione-tuple-space-provider` command
    #

    compdef _pione-tuple-space-provider pione-tuple-space-provider

    _pione-tuple-space-provider() {
        _pione-tuple-space-provider_options
    }

    _pione-tuple-space-provider_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--communication-address=ADDRESS[set IP address for interprocess communication]" "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--notification-address=ADDRESS[set the address for sending notification packet]" "--parent-front=URI[set parent front URI]" '*:file:_files' && return 0;
    }

    #
    # `pione-tuple-space-receiver` command
    #

    compdef _pione-tuple-space-receiver pione-tuple-space-receiver

    _pione-tuple-space-receiver() {
        _pione-tuple-space-receiver_options
    }

    _pione-tuple-space-receiver_options() {
        _arguments -s -S "--\[no-\]color[turn on/off color mode]" "--communication-address=ADDRESS[set IP address for interprocess communication]" "--debug\[=TYPE\][turn on debug mode about the type(system / rule_engine / ignored_exception / notifier / communication)]" "--notification-port=PORT[set notification port number]" "--parent-front=URI[set parent front URI]" '*:file:_files' && return 0;
    }

fi
