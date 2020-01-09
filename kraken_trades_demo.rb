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
#    Copyright (C) 2016-2020 Jon Atack <jon@atack.com>
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
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.push(lib) unless $LOAD_PATH.include?(lib)
require 'kraken_ruby_client'

# User settings ##############################################################
# Wait 6 seconds per call to not exceed the Kraken API rate limit.
# Tier 3 users can lower this to 4 seconds, and Tier 4 users to 2 seconds.
CALL_LIMIT_TIME = 4

# These are your price alert settings.
# After each alert, the threshold is adjusted outward by the greater value
# between the latest price, or the threshold multiplied by this coefficent:
PRICE_ALERT_ADJUST_COEFF = 1.001
# Set your price alert thresholds here. Use nil when no price alert wanted.
PRICE_ALERT_THRESHOLDS = {
  'USD' => { less_than: nil, more_than: nil },
  'EUR' => { less_than: 5200, more_than: 5225 }
}.freeze

# Price alerts per currency. True for yes, false for no.
PRICE_ALERTS    = { 'USD' => false, 'EUR' => true }.freeze

# Audible settings per currency. True for audio+text, false for text only.
AUDIBLE_TRADES  = { 'USD' => false, 'EUR' => false }.freeze
##############################################################################

# Main trade info loop.
class TradeDemo
  CURRENCIES = %w(USD EUR).freeze
  PAIRS = { 'USD' => 'XXBTZUSD', 'EUR' => 'XXBTZEUR' }.freeze

  def initialize
    @kraken = Kraken::Client.new
  end

  def run
    loop do
      CURRENCIES.each do |currency|
        begin
          query = get_trades(currency)
          errors, result = query.fetch('error'), query.fetch('result')
          if errors.any?
            DisplayErrorMessages.new(errors, currency).call
          elsif (trades = result.fetch(PAIRS.fetch(currency))).any?
            output_trades(trades, currency)
            memoize_last_trade_id(result.fetch('last'), currency)
          end
        rescue StandardError
          DisplayErrorMessages.new.host_resolution_error
        end
        sleep CALL_LIMIT_TIME
      end
    end
  end

  private

  def get_trades(currency)
    @kraken.trades(PAIRS.fetch(currency), last_trade.fetch(currency))
  end

  def last_trade
    @last_trade ||= { 'USD' => nil, 'EUR' => nil }.freeze
  end

  def price_alerts
    @price_alerts ||= PRICE_ALERT_THRESHOLDS
  end

  def output_trades(trades, currency)
    trades_to_display(trades, currency).each do |trade|
      OutputTradeInfo.new(trade, currency, price_alerts).call
    end
  end

  def trades_to_display(trades, currency)
    if last_trade.fetch(currency)
      trades
    else
      [trades.last]
    end
  end

  def memoize_last_trade_id(last_trade_id, currency)
    last_trade[currency] = last_trade_id
  end
end

class OutputTradeInfo
  CURRENCY_SYMBOL = { 'USD' => '$', 'EUR' => '€', 'XBT' => '฿' }.freeze
  CURRENCY_WORD = {
    'USD' => 'dollars',
    'EUR' => 'euros',
    'XBT' => 'bitcoins'
  }.freeze
  MARKET_OR_LIMIT = { 'l' => 'limit', 'm' => 'market' }.freeze
  BUY_OR_SELL = { 'b' => 'buy ', 's' => 'sell' }.freeze
  TEXT_COLORS = { 'b' => :green, 's' => :red   }.freeze
  ANSI_COLOR_CODES = { default: 38, black: 30, red: 31, green: 32 }.freeze

  def initialize(trade, currency, alerts)
    @price, volume, @unixtime, @operation, @type, @misc = trade
    @price_f, @volume = @price.to_f, volume[0..-5]
    @currency, @alerts = currency, alerts
    @lower_alert_threshold = alerts.fetch(@currency).fetch(:less_than)
    @upper_alert_threshold = alerts.fetch(@currency).fetch(:more_than)
  end

  def call
    print_trade
    speak_trade
    run_price_alerts
  end

  def print_trade
    puts "#{tab_for.fetch(@currency)}#{unixtime_to_hhmmss}  " \
      "#{colorize(BUY_OR_SELL.fetch(@operation))}  " \
      "#{CURRENCY_SYMBOL.fetch(@currency)} #{printed_price} " \
      "#{display_volume}  #{MARKET_OR_LIMIT.fetch(@type)}"
  end

  def speak_trade
    return unless AUDIBLE_TRADES.fetch(@currency)

    `say "#{CURRENCY_WORD.fetch(@currency)}: " \
         "#{BUY_OR_SELL.fetch(@operation)}, " \
         "#{spoken_volume} bitcoin, at #{price_to_syllables}"`
  end

  def run_price_alerts
    return unless PRICE_ALERTS.fetch(@currency) && (result = price_alert_action)

    action, old_threshold, new_threshold = result
    old_threshold = cents_rounding_for(old_threshold)

    alert = "In #{CURRENCY_WORD.fetch(@currency)}, " \
      "the price of #{@price_f} is #{action} " \
      "your threshold of #{old_threshold} with the " \
      "#{BUY_OR_SELL.fetch(@operation).strip} of #{spoken_volume} bitcoin."

    puts "\r\n#{alert}\r\nThe price threshold has been updated from " \
      "#{old_threshold} to #{cents_rounding_for(new_threshold)}.\r\n\r\n"

    `say "#{alert}"`
  end

  private

  def price_alert_action
    if @lower_alert_threshold && @price_f < @lower_alert_threshold
      ['below', @lower_alert_threshold, update_lower_price_alert!]
    elsif @upper_alert_threshold && @price_f > @upper_alert_threshold
      ['above', @upper_alert_threshold, update_upper_price_alert!]
    end
  end

  def update_lower_price_alert!
    @alerts.fetch(@currency)[:less_than] =
      [(@lower_alert_threshold / PRICE_ALERT_ADJUST_COEFF), @price_f].min
  end

  def update_upper_price_alert!
    @alerts.fetch(@currency)[:more_than] =
      [(@upper_alert_threshold * PRICE_ALERT_ADJUST_COEFF), @price_f].max
  end

  def cents_rounding_for(price)
    price.round(2)
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
    @price_f
      .round(1)
      .to_s.each_char.to_a.join(' ')
      .sub('. 0', '').sub('.', 'point')
  end

  def display_volume
    "#{' ' * (9 - @volume.size)}#{colorize(@volume, 1)} " +
      CURRENCY_SYMBOL.fetch('XBT')
  end

  def tab_for
    {
      'USD' => '',
      'EUR' => '                                                '
    }.freeze
  end

  def unixtime_to_hhmmss
    Time.at(@unixtime).strftime('%H:%M:%S')
  end

  def colorize(text, volume_threshold = nil)
    return text if volume_threshold && text.to_i < volume_threshold

    color = ANSI_COLOR_CODES.fetch(TEXT_COLORS.fetch(@operation))

    "\033[#{color}m#{text}\033[0m"
  end
end

class DisplayErrorMessages
  # The Kraken API returns an array of error message strings
  # in the following format:
  # <char-severity code><str-error category>:<str-error type>[:<str-extra info>]
  # Example: 'EAPI:Rate limit exceeded'
  # The severity code can be E for error or W for warning.
  def initialize(errors_array = nil, currency = nil)
    @errors_array, @currency = errors_array, currency
  end

  def call
    @errors_array.each do |message|
      puts format_error_message(message)
    end
  end

  def host_resolution_error
    puts "\r\nCouldn't resolve host name (Curl::Err::HostResolutionError)." \
         "\r\n\r\n"
  end

  private

  def format_error_message(string)
    parts = string[1..-1].split(':')
    description = "'#{parts.first} #{parts.last.downcase}'"

    "#{error_code.fetch(string[0])}: " \
      "#{description} in #{@currency} trades query!"
  end

  def error_code
    { 'E' => 'Error', 'W' => 'Warning' }.freeze
  end
end

k = TradeDemo.new
k.run
