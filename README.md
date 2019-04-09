# Kraken Ruby Client

A Ruby API wrapper for the Kraken cryptocurrency exchange.

Emphasis on speed, simplicity, no meta-programming, and few dependencies.

Kraken Ruby Client:

- follows
[X-ISO4217-A3 Internet Standards Draft Registry Contents](https://github.com/globalcitizen/x-iso4217-a3),
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

Currently developed with Ruby 2.6. Written for Ruby 2.4 and up.

# Getting started

Clone the repository, and in the local directory, run `gem install curb ; bundle install`.

Launch the interactive Ruby shell from the terminal with

```
$ irb -I lib
```

or with the rake task

```
$ rake console
```

Inside the interactive Ruby console, ensure that `require 'curb'` does not raise any errors. If it does, Curb may not be properly installed or your system may be missing necessary dependencies. See the [Curb documentation](https://github.com/taf2/curb) for more info.

### Public API examples

```ruby
require 'kraken_ruby_client'
client = Kraken::Client.new

client.server_time
client.assets
client.assets('USD')
client.assets('xbt,zec,dash,xmr,eth,etc,usd,eur,gbp,jpy')
client.asset_pairs
client.asset_pairs(:zecusd)
client.asset_pairs('xbtusd,etheur')
client.ticker('xbtusd,xmreur,ethgbp,ethjpy')
client.ohlc(:xbtusd)
client.order_book('etheur')
client.trades('DASHXBT')
client.spread(:XMREUR)
client.spread('XBTJPY')
```

### Private API examples

```ruby
require 'kraken_ruby_client'
client = Kraken::Client.new(api_key: 'YOUR_API_KEY', api_secret: 'YOUR_API_SECRET')

client.balance
client.add_order(pair: 'XBTEUR', type: 'buy', ordertype: 'market', volume: 0.5)
client.open_orders.dig('result', 'open')
```


# API

## Public API

### Get OHLC (Open, High, Low, Close) data

```ruby
# Get OHLC (Open, High, Low, Close) data
# URL: https://api.kraken.com/0/public/OHLC
# Input:
#   +pair+     = required asset pair for which to query OHLC data
#   +interval+ = optional time frame interval in minutes. Defaults to 1.
#                Permitted values: 1, 5, 15, 30, 60, 240, 1440, 10080, 21600
#                Returns an Invalid Arguments error for other values.
#   +since+    = optional Unix Time from when to return committed OHLC data
#
# Returns a hash with keys `error' and `result'.
#   +result+ is an array containing pair name, OHLC data, and last Unixtime.
#   The OHLC data array contains:
#     time, open, high, low, close, VWAP, price, volume, count.
#   The last entry in the OHLC data array is for the current, not-yet-
#   committed frame and is always present, regardless of the value of since.
#   +last+ is to be used as `since' when getting new committed OHLC data.

client.ohlc('XBTUSD'
client.ohlc('xbtjpy', interval: 5)
client.ohlc('ETHGBP', since: 1548525720)
client.ohlc('xmrusd', interval: 15, since: 1548525720)
```

## Private API

### Fetch account balances

```ruby
client.balance
```

### Fetch closed orders

```ruby
# Fetch all closed orders and a display a readable summary.
closed_orders = client.closed_orders.dig('result', 'closed') # All closed orders
closed_orders.first # Show the most recent closed order

# Show a readable list of the last 5 closed orders.
closed_orders.first(5).each { |order| puts "#{order[0]} - #{order[1].dig('descr', 'order')}" }

# More elaborate version, with order date and improved readibility for the
# last 10 closed orders of an asset pair.
pair = 'LTCEUR'
closed_orders.select { |_, v| v.dig('descr', 'pair') == pair }.first(10).each do |order|
  action, price, *rest = order[1].dig('descr', 'order').split
  puts "#{order[0]}   #{Time.at(order[1]['opentm'])}   " \
    "#{action}#{' ' if action.size == 3}  "#{price[0..4]} #{rest.join(' ')}"
end
```

### Fetch open orders

```ruby
# Fetch all open orders, the most recent open order, and total open order count.
open_orders = client.open_orders.dig('result', 'open') # All open orders
open_orders.first # Most recent open order
open_orders.count # Number of open orders

# List the open orders for an asset pair and the most recent order for the pair.
pair = 'ETCUSD'
open_orders.select { |_, v| v.dig('descr', 'pair') == pair } # All open orders
open_orders.detect { |_, v| v.dig('descr', 'pair') == pair } # Most recent open order

# More elaborate version, with order date and improved readibility for the
# last 10 open orders of an asset pair.
open_orders.select { |_, v| v.dig('descr', 'pair') == pair }.first(10).each do |order|
  action, price, *rest = order[1].dig('descr', 'order').split
  puts "#{order[0]}   #{Time.at(order[1]['opentm'])}   " \
    "#{action}#{' ' if action.size == 3}  #{price[0..4]} #{rest.join(' ')}"
end
```

### Place a limit buy order

```ruby
client.add_order(pair: 'LTCEUR', type: 'buy', ordertype: 'limit', volume: 1, price: 50.5)
```

### Place a market buy order

```ruby
client.add_order(pair: 'XBTEUR', type: 'buy', ordertype: 'market', volume: 0.5)
```

### Place a margin sell order (short)

```ruby
client.add_order(pair: 'DASHEUR', type: 'sell', ordertype: 'market', volume: 1, leverage: 2)
```

### Cancel an order

```ruby
client.cancel_order('TRANSACTION_ID')
```


## Running the test suite

To run all tests: `rake test` or just `rake`

To run one test file: `rake TEST=test/public_api_test.rb`

To run an individual test in a test file:
`rake TEST=test/public_api_test.rb TESTOPTS=--name=test_get_server_time`


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

Copyright © 2016-2019 Jon Atack (@jonatack)
