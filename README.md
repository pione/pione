# Pione

PIONE is Process-rule for Input/Output Negotiation Enviromenment.

## Installation

    $ gem install pione

## Usage

### Stand alone mode

    $ pione-stand-alone example/Fib/Fib.pione

### Distribution mode

1. Start brokers on machines.

   $ pione-broker

2. Request process manager to process the rule document.

   $ pione-process-manager example/CountChar/CountChar.pione

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
