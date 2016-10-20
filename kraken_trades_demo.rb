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

# User settings ##############################################################

# Wait 6 seconds per call to not exceed the Kraken API rate limit.
# Tier 3 users can lower this to 4 seconds, and Tier 4 users to 2 seconds.
CALL_LIMIT_TIME           = 6

# These are your price alert settings.
# After each alert, the threshold is adjusted outward by the greater value
# between the latest price, or the threshold multiplied by this coefficent:
PRICE_ALERT_ADJUST_COEFF = 1.0004
# Set your price alert thresholds here. Use nil when no price alert wanted.
PRICE_ALERT_THRESHOLDS = {
  'USD' => {
    less_than: 616.4,
    more_than: 621
  },
  'EUR' => {
    less_than: 553.3752,
    more_than: nil
  }
}

# Audible settings per currency. True for audio+text, false for text only.
AUDIBLE_TRADES = { 'USD' => false, 'EUR' => false }

##############################################################################

class TradeDemo
  CURRENCIES = %w(USD EUR)
  PAIRS = {
    'USD' => 'XXBTZUSD',
    'EUR' => 'XXBTZEUR'
  }

  def initialize
    @kraken = Kraken::Client.new
  end

  def run
    loop do
      CURRENCIES.each do |currency|
        query = @kraken.trades(PAIRS[currency], last_trade[currency])
        errors, result = query['error'], query['result']
        if errors.any?
          ErrorMessage.new(errors, currency).display_error_messages
        elsif result[PAIRS[currency]].any?
          output_trades(result[PAIRS[currency]], currency)
          memoize_last_trade_id(result['last'], currency)
        end
        sleep CALL_LIMIT_TIME
      end
    end
  end

  private

    def last_trade
      @last_trade ||= { 'USD' => nil, 'EUR' => nil }
    end

    def price_alerts
      @price_alerts ||= PRICE_ALERT_THRESHOLDS
    end

    def output_trades(trades, currency)
      (last_trade[currency] ? trades : [trades.last]).each do |trade|
        Trade.new(trade, currency, price_alerts).handle_trade
      end
    end

    def memoize_last_trade_id(last_trade_id, currency)
      last_trade[currency] = last_trade_id
    end
end

class Trade
  CURRENCY_SYMBOL = {
    'USD' => '$',
    'EUR' => '€',
    'XBT' => '฿'
  }
  CURRENCY_WORD = {
    'USD' => 'dollars',
    'EUR' => 'euros',
    'XBT' => 'bitcoins'
  }
  MARKET_OR_LIMIT = {
    'l' => 'limit',
    'm' => 'market'
  }
  BUY_OR_SELL = {
    'b' => 'buy ',
    's' => 'sell'
  }
  TEXT_COLORS = {
    'b' => :green,
    's' => :red
  }
  ANSI_COLOR_CODES = {
    default: 38,
    black:   30,
    red:     31,
    green:   32
  }

  def initialize(trade, currency, alerts)
    @price, volume, @unixtime, @operation, @type, @misc = trade
    @price_f, @volume = @price.to_f, volume[0..-5]
    @currency, @alerts = currency, alerts
  end

  def handle_trade
    print_trade
    speak_trade
    run_price_alerts
  end

  private

    def print_trade
      puts "#{tab_for[@currency]}#{unixtime_to_hhmmss}  #{
        colorize(BUY_OR_SELL[@operation])}  #{
        CURRENCY_SYMBOL[@currency]} #{printed_price} #{
        display_volume}  #{MARKET_OR_LIMIT[@type]}"
    end

    def speak_trade
      return unless AUDIBLE_TRADES[@currency]
      %x(say "#{CURRENCY_WORD[@currency]}: #{BUY_OR_SELL[@operation]}, #{
        spoken_volume} bitcoin, at #{price_to_syllables}")
    end

    def run_price_alerts
      return unless result = price_alert_action
      action, old_threshold, new_threshold = result
      alert = "Price alert: In #{CURRENCY_WORD[@currency]
              }, the price of #{@price_f} is #{action
              } your threshold of #{old_threshold.round(2)
              } with the #{BUY_OR_SELL[@operation].strip
              } of #{spoken_volume} bitcoin."
      puts "\r\n#{alert}\r\nThe price threshold has been updated from #{
            old_threshold} to #{new_threshold.round(3)}.\r\n\r\n"
      %x(say "#{alert}")
    end

    def price_alert_action(coeff = PRICE_ALERT_ADJUST_COEFF)
      lo, hi = @alerts[@currency][:less_than], @alerts[@currency][:more_than]
      if lo && @price_f < lo
        @alerts[@currency][:less_than] = [(lo / coeff), @price_f].min
        ['below', lo, @alerts[currency][:less_than]]
      elsif hi && @price_f > hi
        @alerts[@currency][:more_than] = [(hi * coeff), @price_f].max
        ['above', hi, @alerts[@currency][:more_than]]
      end
    end

    def printed_price
      @price[0..-3]
    end

    def spoken_volume
      if (round_volume = @volume.to_f.round(1)) < 1
        'less than one'
      else
        round_volume
      end
    end

    def price_to_syllables
      @price_f.round(1).to_s.each_char.to_a.join(' ')
      .sub('. 0', '').sub('.', 'point')
    end

    def display_volume
      "#{' ' * (9 - @volume.size)}#{colorize(@volume, 1)} #{
        CURRENCY_SYMBOL['XBT']}"
    end

    def tab_for
      { 'USD' => '',
        'EUR' => '                                                ' }.freeze
    end

    def unixtime_to_hhmmss
      Time.at(@unixtime).strftime('%H:%M:%S')
    end

    def colorize(text, volume_threshold = nil)
      return text if volume_threshold && text.to_i < volume_threshold
      "\033[#{ANSI_COLOR_CODES[TEXT_COLORS[@operation]]}m#{text}\033[0m"
    end
end

class ErrorMessage
  # The Kraken API returns an array of error message strings
  # in the following format:
  #
  # <char-severity code><str-error category>:<str-error type>[:<str-extra info>]
  #
  # Example: 'EAPI:Rate limit exceeded'
  #
  # The severity code can be E for error or W for warning.
  #
  def initialize(errors_array, currency)
    @errors_array, @currency = errors_array, currency
  end

  def display_error_messages
    @errors_array.each do |message|
      puts format_error_message(message)
    end
  end

  private
    def format_error_message(string)
      parts = string[1..-1].split(':')
      description = "'#{parts.first} #{parts.last.downcase}'"
      "#{error_code[string[0]]}: #{description} in #{@currency} trades query!"
    end

    def error_code
      { 'E' => 'Error', 'W' => 'Warning' }.freeze
    end
end

k = TradeDemo.new
k.run
