% pione-list-param(1) PIONE User Manual
% Keita Yamaguchi

# NAME

pione-list-param - show a list of parameters in the document or package.

# SYNOPSIS

**pione list-param** [options] location

# DESCRIPTION

**list-param** command shows a list of parameters in the document or
package. The list includes basic parameters only by default, set `--advanced` option
if you want to show advanced parameters.

# OPTIONS

-a, --advanced
:   Show advanced parameters.

# EXAMPLES

pione list-param example/HelloWorld/HelloWorld.pione
:    Show basic parameters in the document `example/HelloWorld/HelloWorld.pione`.

pione list-param example/HelloWorld
:    Show basic parameters in the package `example/HelloWorld`.

pione list-param --advanced example/HelloWorld
:    Show basic and advanced parameters in the package `example/HelloWorld`.

# REPORTING BUGS

Report bugs or feature requests to PIONE's issue tracker(https://github.com/pione/pione/issues).
