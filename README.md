# PIONE

PIONE is Process-rule for Input/Output Negotiation Enviromenment. You can write
complex process as simple rules and run it with distributing many machines easily.

Currently PIONE is beta version under heavy development.

## Features

* multi-agent rule system
* forward chain reasoning with multipule domains model as extension of production rule system
* task distribution according to RINDA
* data distribution with network services like Dropbox

## Installation

Clone the repository from https://github.com/pione/pione.git.

   $ git clone https://github.com/pione/pione.git

And you add paths to pione like the flowing:

   $ cd ${PIONE_REP}
   $ export PATH=$PWD/bin:$PATH
   $ export RUBYLIB=$PWD/lib

## Usage

### Client

   $ pione-client example/Fib/Fib.pione

### Stand alone mode

   $ pione-client example/Fib/Fib.pione --stand-alone

### Distribution mode

1. Start brokers on machines.

   $ pione-broker

2. Request process manager to process the rule document.

   $ pione-client example/Fib/Fib.pione

### Help

   $ pione-client --help

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Contributors

* Keita Yamaguchi<keita.yamaguchi@gmail.com>

## Licence

PIONE is free software distributed under MIT licence. Except the above, the
following files are distributed under same as Ruby's(Ruby license or BSD)
because these are patches including original codes:

* lib/pione/patch/drb-patch.rb
* lib/pione/patch/monitor-patch.rb
* lib/pione/patch/rinda-patch.rb

