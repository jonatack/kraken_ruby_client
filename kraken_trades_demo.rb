# frozen_string_literal: true
#--
#    kraken_trades_demo.rb
#
#    A funky little script to output Kraken BTCUSD & BTCEUR trades using the
#    Kraken Ruby Client, for Ruby 2.3+ on Mac OS (for the text-to-speech).
#
#    To run it, type `ruby -Ilib kraken_trades_demo.rb` on the command line.
#
#    Copyright (C) 2016 Jon Atack
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Lesser General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.)
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Lesser General Public License for more details.)
#
#    You should have received a copy of the GNU Lesser General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    The author may be contacted by email: jon@atack.com
#++
require 'kraken_ruby_client'

kraken          = Kraken::Client.new
currencies      = %w(USD EUR)
btc_pairs       = { 'USD' => 'XXBTZUSD', 'EUR' => 'XXBTZEUR' }
since           = { 'USD' => nil, 'EUR' => nil }

# Wait 6 seconds per call to not exceed the Kraken API rate limit.
# Tier 3 users can lower this to 4 seconds, and Tier 4 users to 2 seconds.
call_limit_time = 6

def digits_to_syllables(num)
  num.to_s.each_char.to_a.join(' ').sub('. 0', '').sub('.', 'point')
end

def print_trade(currency, operation, price, volume)
  puts "#{price} #{currency} #{volume} BTC #{operation}"
end

def speak_trade(currency, operation, price, volume)
  %x(say "#{currency}: #{operation}, #{volume} bitcoin, at #{price}.")
end

loop do
  currencies.each do |currency|
    query = kraken.trades(btc_pairs[currency], since[currency])
    if query['error'].any?
      puts "Error in #{currency} trades query!"
    else
      trades, pair      = query['result'], btc_pairs[currency]
      since[currency]   = trades['last'] # memoize last trade id
      transactions      = trades[pair]
      number_of_tx      = transactions.size
      next if number_of_tx.zero?

      (number_of_tx < 10 ? transactions : [transactions.last]).each do |trade|
        price, volume, operation = trade[0], trade[1][0..-5], trade[3]
        round_price     = price.to_f.round(2)
        written_price   = "#{round_price}#{'0' if round_price.to_s.size == 5}"
        spoken_price    = digits_to_syllables(round_price.round(1))
        round_volume    = volume.to_f.round(1)
        spoken_volume   = round_volume < 1 ? 'less than one' : round_volume
        spoken_currency = currency == 'USD' ? 'Dollars' : 'Euros'
        buy_or_sell     = operation == 'b' ? 'buy' : 'sell'

        print_trade(currency, buy_or_sell, written_price, volume)
        speak_trade(spoken_currency, buy_or_sell, spoken_price, spoken_volume)
      end
    end
    sleep call_limit_time
  end
end
