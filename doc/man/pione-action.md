% pione-action(1) PIONE User Manual
% Keita Yamaguchi

# NAME

pione-action - execute an action in literate action document.

# SYNOPSIS

**pione action** [options] location action_name

# DESCRIPTION

**action** command execute or show an action in literate action document.

# OPTIONS

--show
:   Show an action instead of execution.

-d, --directory PATH
:   Execute an action in the directory.

# EXAMPLES

pione action HelloWorld.md SayHello
:    Execute `SayHello` action of `HelloWorld.md` in current directory.

pione action -d /tmp HelloWorld.md SayHello
:    Execute `SayHello` action of `HelloWorld.md` in /tmp.

pione action HelloWorld.md SayHello --show
:    Show `SayHello` action of `HelloWorld.md`.

# REPORTING BUGS

Report bugs or feature requests to PIONE's issue tracker(https://github.com/pione/pione/issues).
