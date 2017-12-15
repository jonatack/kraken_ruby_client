# Kraken Ruby Client

A work-in-progress Ruby API wrapper for the Kraken Bitcoin Exchange.

Emphasis on speed, simplicity, no meta-programming, and few dependencies.

Kraken Ruby Client:

- follows
[Proposal X-ISO4217-A3](http://www.ifex-project.org/our-proposals/x-iso4217-a3),
an API standards protocol for the open identification of currencies and
currency-like commodities on the internet by the
[Internet Financial EXchange (IFEX)](http://www.ifex-project.org/) organisation.

- has only one runtime dependency:
The fast [Curb (CUrl-RuBy) gem](https://github.com/taf2/curb), which provides
Ruby bindings for [libcurl](https://github.com/curl/curl), a fully-featured
client-side URL transfer library written in C.

- does not use [Hashie](https://github.com/intridea/hashie),
to avoid the [pain and performance costs](http://www.schneems.com/2014/12/15/hashie-considered-harmful.html) of [subclassing Hash](http://tenderlovemaking.com/2014/06/02/yagni-methods-are-killing-me.html).

- uses fast, straightforward, assertions-style
[Minitest](https://github.com/seattlerb/minitest) for its test suite.

Currently developed with Ruby 2.4.0. Written for Ruby 2.3 and up.

## Getting started

On the command line, launch the interactive Ruby shell:
```
$ irb -I lib
```

Examples of using the public API:
```ruby
require 'kraken_ruby_client'; client = Kraken::Client.new

client.server_time
client.assets
client.asset_pairs
client.ticker('XBTEUR')
client.ohlc('XBTUSD')
client.order_book('ETHEUR')
client.trades('DASHXBT')
client.spread('XMREUR')
```

## Usage

Enter the interactive Ruby shell:

```
$ irb -I lib
```

To use the private API to access your account:

```ruby
require 'kraken_ruby_client'
client = Kraken::Client.new(api_key: 'YOUR_API_KEY', api_secret: 'YOUR_API_SECRET')
```

Fetch account balances:

```ruby
client.balance
```

Fetch all closed orders and the most recent closed order:

```ruby
closed_orders = client.closed_orders.dig('result', 'closed') # All closed orders
closed_orders.first # Most recent closed order
```

Fetch all open orders, the most recent open order, and total open order count:

```ruby
open_orders = client.open_orders.dig('result', 'open') # All open orders
open_orders.first # Most recent open order
open_orders.count # Number of open orders
```

List the open orders for a specific pair and the last order for the pair:

```ruby
pair = 'ETCUSD'
orders.select { |_, v| v.dig('descr', 'pair') == pair } # All
orders.detect { |_, v| v.dig('descr', 'pair') == pair } # Most recent order
```

Place a market buy order:
```ruby
client.add_order(pair: 'XBTEUR', type: 'buy', ordertype: 'market', volume: 0.5)
```

Place a margin sell order (short):
```ruby
client.add_order(pair: 'DASHEUR', type: 'sell', ordertype: 'market', volume: 1, leverage: 2)
```

Cancel an order:
```ruby
client.cancel_order('TRANSACTION_ID')
```

## Running the test suite

To run all tests: `bundle exec rake` or `bundle exec rake test`

To run one test file:
  `ruby -Ilib:test test/private_api_test.rb`
  or
  `rake test TEST=test/public_api_test.rb`

To run an individual test in a test file:
  `ruby -Ilib:test test/public_api_test.rb -n test_get_server_time`
  or
  `rake test TEST=test/public_api_test.rb TESTOPTS=--name=test_get_server_time`


## Contributions

To support the project:

* Use Kraken Ruby Client in your apps, and please file an issue if you
encounter anything that's broken or missing. A failing test to demonstrate
the issue is awesome. A pull request with passing tests is even better!

## License/disclaimer

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

The author may be contacted by email at jon@atack.com.

Copyright © 2017 Jon Atack (@jonatack)
