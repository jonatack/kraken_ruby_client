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

def alerts
  {
    'USD' => { less_than: 608.00, greater_than: 612.70 }.freeze,
    'EUR' => { less_than: 544.00, greater_than: 547.99 }.freeze
  }.freeze
end

kraken          = Kraken::Client.new
currencies      = %w(USD EUR)
pairs           = { 'USD' => 'XXBTZUSD', 'EUR' => 'XXBTZEUR' }
since           = { 'USD' => nil, 'EUR' => nil }
# Wait 6 seconds per call to not exceed the Kraken API rate limit.
# Tier 3 users can lower this to 4 seconds, and Tier 4 users to 2 seconds.
call_limit_time = 6

def currency_symbol
  { 'USD' => '$', 'EUR' => '€' }.freeze
end

def digits_to_syllables(num)
  num.to_s.each_char.to_a.join(' ').sub('. 0', '').sub('.', 'point')
end

def spoken_currency(currency)
  currency == 'USD' ? 'Dollars' : 'Euros'
end

def buy_or_sell(operation)
  operation == 'b' ? 'buy ' : 'sell'
end

def ansi_codes
  { default: 38, black: 30, red: 31, green: 32 }.freeze
end

def colorize(text, operation, volume = nil, volume_threshold = 10)
  return volume if volume && volume.to_i < volume_threshold
  color = operation == 'b' ? :green : :red
  "\033[#{ansi_codes[color]}m#{text}\033[0m"
end

def unixtime_to_hhmmss(unixtime)
  Time.at(unixtime).strftime('%H:%M:%S')
end

def tab_for(currency)
  '                                                ' if currency == 'EUR'
end

def market_or_limit(type)
  type == 'l' ? 'limit' : 'market'
end

def print_trade(currency, operation, price, volume, time, type)
  puts "#{tab_for(currency)}#{unixtime_to_hhmmss(time)}  #{
    colorize(buy_or_sell(operation), operation)}  #{
    currency_symbol[currency]} #{price[0..-3]} #{
    ' ' * (7 - volume.size)}#{colorize(volume, operation, volume)} ฿  #{
    market_or_limit(type)}"
end

def speak_trade(currency, operation, price, volume)
  %x(say "#{spoken_currency(currency)}: #{buy_or_sell(operation)}, #{volume
          } bitcoin, at #{price}")
end

def speak_price_alert(currency, operation, price, volume)
  return unless action = price_alert_reached?(price, currency)
  %x(say "Price alert! In #{spoken_currency(currency)}, the price of #{price
          } is #{action} with #{buy_or_sell(operation)}, #{volume} bitcoin")
end

def price_alert_reached?(price, currency)
  low, high = alerts[currency][:less_than], alerts[currency][:greater_than]
  if price < low
    "below, your threshold of #{low}"
  elsif price > high
    "above, your threshold of #{high}"
  end
end

loop do
  currencies.each do |currency|
    query = kraken.trades(pairs[currency], since[currency])
    if query['error'].any?
      error_messages = query['error'].join(' - ')
      puts "Error '#{error_messages}' in #{currency} trades query!"
    else
      trades            = query['result']
      since[currency]   = trades['last']          # memoize last trade id
      transactions      = trades[pairs[currency]]
      number_of_tx      = transactions.size
      next if number_of_tx.zero?

      (number_of_tx < 40 ? transactions : [transactions.last]).each do |trade|
        price, volume, time, operation, type, misc = trade
        price_f         = price.to_f
        volume          = volume[0..-6]
        spoken_price    = digits_to_syllables(price_f.round(1))
        round_volume    = volume.to_f.round(1)
        spoken_volume   = round_volume < 1 ? 'less than one' : round_volume

        print_trade(currency, operation, price, volume, time, type)
        # speak_trade(currency, operation, spoken_price, spoken_volume)
        speak_price_alert(currency, operation, price_f, spoken_volume)
      end
    end
    sleep call_limit_time
  end
end
