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

lib = File.expand_path('../lib', __FILE__)
$:.push(lib) unless $:.include?(lib)

require 'kraken_ruby_client'

class Trades
  CURRENCIES                = %w(USD EUR)
  PAIRS                     = { 'USD' => 'XXBTZUSD',  'EUR' => 'XXBTZEUR' }
  CURRENCY_WORD             = { 'USD' => 'Dollars',   'EUR' => 'Euros' }
  CURRENCY_SYMBOL           = { 'USD' => '$',         'EUR' => '€' }
  BUY_OR_SELL               = { 'b'   => 'buy',       's'   => 'sell' }
  MARKET_OR_LIMIT           = { 'l'   => 'limit',     'm'   => 'market' }

  TEXT_COLORS               = { 'b'   => :green,      's'   => :red }
  ANSI_COLOR_CODES          = { default: 38, black: 30, red: 31, green: 32 }

  # Wait 6 seconds per call to not exceed the Kraken API rate limit.
  # Tier 3 users can lower this to 4 seconds, and Tier 4 users to 2 seconds.
  CALL_LIMIT_TIME           = 6

  def initialize
    @kraken = Kraken::Client.new
  end

  def run
    loop do
      CURRENCIES.each do |currency|
        query = @kraken.trades(PAIRS[currency], since[currency])
        if query['error'].any?
          error_messages = query['error'].join(' - ')
          puts "Error '#{error_messages}' in #{currency} trades query!"
        else
          trades            = query['result']
          since[currency]   = trades['last'] # memoize last trade id
          transactions      = trades[PAIRS[currency]]
          number_of_tx      = transactions.size
          next if number_of_tx.zero?

          (number_of_tx < 100 ? transactions : [transactions.last]).each do |trade|
            price, volume, time, operation, type, misc = trade
            price_f         = price.to_f
            volume          = volume[0..-5]
            spoken_price    = digits_to_syllables(price_f.round(1))
            round_volume    = volume.to_f.round(1)
            spoken_volume   = round_volume < 1 ? 'less than one' : round_volume

            print_trade(currency, operation, price, volume, time, type)
            speak_trade(currency, operation, spoken_price, spoken_volume)
          end
        end
        sleep CALL_LIMIT_TIME
      end
    end
  end

  private

  def since
    @since ||= { 'USD' => nil, 'EUR' => nil }
  end

  def print_trade(currency, operation, price, volume, time, type)
    puts "#{tab_for[currency]}#{unixtime_to_hhmmss(time)}  #{
      colorize(BUY_OR_SELL[operation], operation)}  #{
      CURRENCY_SYMBOL[currency]} #{price[0..-3]} #{
      ' ' * (7 - volume.size)}#{colorize(volume, operation, volume)} ฿  #{
      MARKET_OR_LIMIT[type]}"
  end

  def speak_trade(currency, operation, price, volume)
    %x(say "#{CURRENCY_WORD[currency]}: #{BUY_OR_SELL[operation]}, #{volume
            } bitcoin, at #{price}")
  end

  def digits_to_syllables(num)
    num.to_s.each_char.to_a.join(' ').sub('. 0', '').sub('.', 'point')
  end

  def unixtime_to_hhmmss(unixtime)
    Time.at(unixtime).strftime('%H:%M:%S')
  end

  def colorize(text, operation, volume = nil, volume_threshold = 10)
    return volume if volume && volume.to_i < volume_threshold
    "\033[#{ANSI_COLOR_CODES[TEXT_COLORS[operation]]}m#{text}\033[0m"
  end

  def tab_for
    { 'USD' => '',
      'EUR' => '                                                ' }.freeze
  end
end

k = Trades.new
k.run
