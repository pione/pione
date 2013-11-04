% pione-update-package-info(1) PIONE User Manual
% Keita Yamaguchi

# NAME

pione-update-package-info - update PIONE's package information files.

# SYNOPSIS

**pione update-package-info** [options] pacakge-location

# DESCRIPTION

pione-update-package-info updates PIONE's package information files. PIONE tries
to update package information files automatically, but you should update it by
this command when you add new files or do some operations.

## NOTE

This command tries to update files from criterion of file timestamps. If files
are not updated by PIONE's mistake, you need to set `--force` option.

# OPTIONS

--force
:   Update all package information files ignoring the update criterion.

# EXAMPLES

pione update-package-info example/HelloWorld
:    Update some package information files in the path of example/HelloWorld.

pione update-package-info --force example/HelloWorld
:    Update all package information files in the path of example/HelloWorld.

# REPORTING BUGS

Report bugs or feature requests to PIONE's issue tracker(https://github.com/pione/pione/issues).
