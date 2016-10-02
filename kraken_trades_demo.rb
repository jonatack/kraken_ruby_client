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

loop do
  currencies.each do |currency|
    trades = kraken.trades(btc_pairs[currency], since[currency])
    if trades['error'].any?
      puts "Error in #{currency} trades query!"
    else
      since[currency] = trades['result']['last']
      next unless query = trades['result'][btc_pairs[currency]]&.last

      price           = query[0]
      volume          = query[1][0..-5] # Remove trailing zeroes.
      operation       = query[3]

      rounded_price   = price.to_f.round(2)
      written_price   = "#{rounded_price}#{'0' if rounded_price.to_s.size == 5}"
      spoken_price    = digits_to_syllables(rounded_price.round(1))
      rounded_volume  = volume.to_f.round(1)
      spoken_volume   = rounded_volume < 1 ? 'less than one' : rounded_volume
      spoken_currency = currency == 'USD' ? 'dollars' : 'euros'
      op              = operation == 'b' ? 'bought' : 'sold'

      puts "#{written_price} #{currency} #{volume} BTC #{op}"
      %x(say "#{spoken_volume} bitcoin #{op}, at #{spoken_price} #{spoken_currency}")
    end
    sleep call_limit_time
  end
end
