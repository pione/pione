% pione-clean(1) PIONE User Manual
% Keita Yamaguchi

# NAME

pione-clean - remove PIONE's temporary files, cache, and etc.

# SYNOPSIS

**pione-clean** [options]

# DESCRIPTION

pione-clean removes PIONE's temporary files, cache, and etc.

## NOTE

Package cache files are not removed if it is in package database.

# OPTIONS

--older=*DATE*
:   Remove files older than the date. *DATE* can be iso8601 format:

        pione-clean --older=2013-10-01

    This means pione-clean command removes files older than 2013-10-01.
    Otherwise it can be days:

        pione-clean --older=10

    This means pione-clean command removes files older than 10 days.

--type=*NAME*
:   Remove only files of the type. *NAME* can be *temporary*, *file-cache*, *package-cache*, or *profile*.

# EXAMPLES

pione-clean
:    Remove all type files.

pione-clean --older=2013-10-01
:    Remove all type files older than 2013-10-01.

pione-clean --older=10
:    Remove all type files older than 10 days.

pione-clean --type=profile
:    Remove profile reports.

pione-clean --type=file-cache --older=30
:    Remove file cache files older than 30 days.

# REPORTING BUGS

Report bugs or feature requests to PIONE's issue tracker(https://github.com/pione/pione/issues).
