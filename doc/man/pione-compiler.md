% pione-compiler(1) PIONE User Manual
% Keita Yamaguchi

# NAME

pione-compiler - compile to PIONE file.

# SYNOPSIS

**pione-compiler** [options] file

# DESCRIPTION

pione-compiler compiles from PNML(Petri Net Markup Language) to PIONE
document. Source PNML file should be written in a manner of PIONE's special
notations. Target PIONE document is printed out to STDOUT.

# OPTIONS

--name=*NAME*
:   Set the package name.

--editor=*NAME*
:   Set the package editor.

--tag=*NAME*
:   Set the package tag.

# EXAMPLES

pione-compiler Sequence.pnml
:    Compile from Sequence.pnml to PIONE document.

pione-compiler --name=Sequence Sequence.pnml
:    Compile from Sequence.pnml to PIONE document with package name "Sequence".

# REPORTING BUGS

Report bugs or feature requests to PIONE's issue tracker(https://github.com/pione/pione/issues).
