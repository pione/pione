# PIONE

PIONE(Process-rule for Input/Output Negotiation Enviromenment) is a rule-based
workflow engine. You can write complex process as simple rules and run it with
distributing many machines easily.

Currently PIONE is beta version under heavy development.

[![Gem Version](https://badge.fury.io/rb/pione.png)](http://badge.fury.io/rb/pione) [![Build Status](https://travis-ci.org/keita/pione.png?branch=master)](https://travis-ci.org/keita/pione) [![Coverage Status](https://coveralls.io/repos/keita/pione/badge.png?branch=master)](https://coveralls.io/r/keita/pione) [![Code Climate](https://codeclimate.com/github/keita/pione.png)](https://codeclimate.com/github/keita/pione)

## Features

* multi-agent rule system
* forward chain reasoning with multipule domains model as extension of production rule system
* task distribution according to LINDA
* data distribution with network file services like Dropbox

## System Requirements

* Ruby 1.9.3 with bundler
* Linux or Unix-like OSs

## Installation

### from gem

    $ gem install pione

### from github

First, clone the repository from https://github.com/pione/pione.git.

    $ git clone https://github.com/pione/pione.git

And get some libraries.

    $ bundle install --path vender/bundle

Add paths to pione like the flowing:

    $ cd ${PIONE_REP}
    $ export PATH=$PWD/bin:$PATH
    $ export RUBYLIB=$PWD/lib

## Usage

### Process PIONE document on client mode

    $ pione-client example/Fib/Fib.pione

### Stand alone mode(client mode without brokers)

    $ pione-client example/Fib/Fib.pione --stand-alone

### Distribution mode

Start brokers on machines.

    $ pione-broker

Request process manager to process the rule document.

    $ pione-client example/Fib/Fib.pione

### Help

    $ pione-client --help

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Licence

PIONE is free software distributed under MIT licence. Except the above, the
following files are distributed under same as Ruby's(Ruby license or BSD)
because these are patches including original codes:

* lib/pione/patch/drb-patch.rb
* lib/pione/patch/monitor-patch.rb
* lib/pione/patch/rinda-patch.rb

## Links

* [PIONE project homepage](http://pione.github.io/)
    * [repository on github](https://github.com/pione/pione)
* [Yasunaga Laboratory](http://www.yasunaga-lab.bio.kyutech.ac.jp/)
    * [EOS](http://www.yasunaga-lab.bio.kyutech.ac.jp/Eos/)([ja](http://www.yasunaga-lab.bio.kyutech.ac.jp/EosJ/))
* [Japan Science and Technology Agency](http://www.jst.go.jp/EN/index.html)([ja](http://www.jst.go.jp/))
     * [Develoment of Systems and Technology and for Advanced Measurement and Analysis](http://www.jst.go.jp/sentan/en/)([ja](http://www.jst.go.jp/sentan/))
* [NaU Data Institute Inc.](http://www.nau.co.jp/index_en.html)([ja](http://www.nau.co.jp/))

