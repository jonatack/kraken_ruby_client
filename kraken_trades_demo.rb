# frozen_string_literal: true
#--
#    kraken_trades_demo.rb
#
#    A funky little script to output Kraken BTCUSD & BTCEUR trades and
#    audible (text-to-speech) price alerts on the command line using the
#    Kraken Ruby Client. Tested with Ruby 2.3+ on Mac OS 10.11.
#
#    To run it, type `ruby kraken_trades_demo.rb` on the command line.
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

  # These are your price alert settings.
  #
  # After each alert, the threshold is adjusted outward by the greater value
  # between the latest price, or the threshold multiplied by this coefficent:
  PRICE_ALERT_ADJUST_COEFF  = 1.0004
  # Set your price alert thresholds here. Use nil when no price alert wanted.
  PRICE_ALERT_THRESHOLDS    = {
    'USD' => {
      less_than: 616.4,
      more_than: 621
    },
    'EUR' => {
      less_than: 553.3752,
      more_than: nil
    }
  }

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
            # speak_trade(currency, operation, spoken_price, spoken_volume)
            speak_price_alert(currency, operation, price_f, spoken_volume)
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

  def alerts
    @alerts ||= PRICE_ALERT_THRESHOLDS
  end

  def print_trade(currency, operation, price, volume, time, type)
    puts "#{tab_for[currency]}#{unixtime_to_hhmmss(time)}  #{
      colorize(BUY_OR_SELL[operation], operation)}  #{
      CURRENCY_SYMBOL[currency]} #{price[0..-3]} #{
      ' ' * (7 - volume.size)}#{colorize(volume, operation, 10)} ฿  #{
      MARKET_OR_LIMIT[type]}"
  end

  def speak_trade(currency, operation, price, volume)
    %x(say "#{CURRENCY_WORD[currency]}: #{BUY_OR_SELL[operation]}, #{volume
            } bitcoin, at #{price}")
  end

  def speak_price_alert(currency, operation, price, volume)
    return unless action = price_alert_action!(price, currency)
    %x(say "Price alert! In #{CURRENCY_WORD[currency]}, the price of #{price
            } is #{action} with the #{BUY_OR_SELL[operation]
            } of #{volume} bitcoin")
  end

  def price_alert_action!(price, currency, coeff = PRICE_ALERT_ADJUST_COEFF)
    lo, hi = alerts[currency][:less_than], alerts[currency][:more_than]
    if lo && price < lo
      alerts[currency][:less_than] = [(lo / coeff).round(2), (lo - price)].min
      "below, your threshold of #{lo}"
    elsif hi && price > hi
      alerts[currency][:more_than] = [(hi * coeff).round(2), (price - hi)].max
      "above, your threshold of #{hi}"
    end
  end

  def digits_to_syllables(num)
    num.to_s.each_char.to_a.join(' ').sub('. 0', '').sub('.', 'point')
  end

  def unixtime_to_hhmmss(unixtime)
    Time.at(unixtime).strftime('%H:%M:%S')
  end

  def colorize(text, operation, volume_threshold = nil)
    return text if volume_threshold && text.to_i < volume_threshold
    "\033[#{ANSI_COLOR_CODES[TEXT_COLORS[operation]]}m#{text}\033[0m"
  end

  def tab_for
    { 'USD' => '',
      'EUR' => '                                                ' }.freeze
  end
end

k = Trades.new
k.run
