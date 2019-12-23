# frozen_string_literal: true

#--
#    test/test_public_api.rb
#
#    Kraken Exchange API client written in Ruby
#    Copyright (C) 2016-2019 Jon Atack <jon@atack.com>
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
require 'time'
require_relative 'test_helper'

# To run all tests: `bundle exec rake` or `bundle exec rake test`
#
# To run one test file:
#  `ruby -Ilib:test test/private_api_test.rb`
#   or
#  `rake test TEST=test/public_api_test.rb`
#
# To run an individual test in a test file:
#  `ruby -Ilib:test test/public_api_test.rb -n test_get_server_time`
#   or
#  `rake test TEST=test/public_api_test.rb TESTOPTS=--name=test_get_server_time`

class PublicApiTest < Minitest::Test
  def setup
    @query = Kraken::Client.new
  end

  def test_get_server_time
    query               = @query.server_time
    server_time         = query['result']
    server_unixtime     = server_time['unixtime']
    server_rfc1123_time = Time.parse server_time['rfc1123']
    user_time           = Time.now.getutc

    assert_kind_of Integer, server_unixtime
    assert_equal (Time.now.to_i / 100), (server_unixtime / 100)

    assert_equal %w(error result), query.keys
    assert_empty query['error']
    assert_equal user_time.yday, server_rfc1123_time.yday
    assert_equal user_time.hour, server_rfc1123_time.hour
  end

  def test_get_assets
    assets = %w(
      ADA ATOM BAT BCH BSV CHF DAI DASH EOS GNO ICX KFEE LINK LSK NANO OMG PAXG
      QTUM SC USDT WAVES XETC XETH XLTC XMLN XREP XTZ XXBT XXDG XXLM XXMR XXRP 
      XZEC ZCAD ZEUR ZGBP ZJPY ZUSD
    )

    query = @query.assets

    assert_instance_of Hash, query
    assert_equal %w(error result), query.keys
    assert_empty query.fetch('error')

    result = query.fetch('result')
    assert_instance_of Hash, result
    assert_equal assets, result.keys
    assert_instance_of Array, result.first

    asset_name, asset_values = result.first
    assert_instance_of String, asset_name
    assert_instance_of Hash, asset_values
    assert_equal %w(aclass altname decimals display_decimals), asset_values.keys

    assert_get_exchange_currency_info_for('ZUSD', 'USD',  4, 2)
    assert_get_exchange_currency_info_for('ZEUR', 'EUR',  4, 2)
    assert_get_exchange_currency_info_for('XXBT', 'XBT', 10, 5)
  end

  def test_get_ohlc
    pair             = 'xbteur'
    asset_pair_error = ['EQuery:Unknown asset pair']
    arguments_error  = ['EGeneral:Invalid arguments']
    query            = @query.ohlc(pair)
    result           = query.fetch('result')
    last             = result.fetch('last')

    assert_instance_of Hash,        query
    assert_equal %w(error result),  query.keys
    assert_empty                    query.fetch('error')
    assert_instance_of Hash,        result
    assert_equal %w(XXBTZEUR last), result.keys
    assert_instance_of Array,       result.first
    assert_instance_of Array,       result.first[1]
    assert_instance_of Integer,     last

    assert_empty @query.ohlc(pair, since: nil).fetch('error')
    assert_empty @query.ohlc(pair, since: last).fetch('error')
    assert_empty @query.ohlc(pair, since: last, interval: 240).fetch('error')
    assert_empty @query.ohlc(pair, since: 0, interval: 21_600).fetch('error')
    assert_empty @query.ohlc(pair, interval: 60).fetch('error')

    assert_equal asset_pair_error, @query.ohlc('abc').fetch('error')
    assert_equal arguments_error,  @query.ohlc.fetch('error')
    assert_equal arguments_error,  @query.ohlc('').fetch('error')
    assert_equal arguments_error,  @query.ohlc(pair, interval: 0).fetch('error')
  end

  def test_get_trades
    pairs = %w(XXBTZEUR XXBTZUSD XETHZEUR XETHZUSD)

    pairs.each do |pair|
      query = @query.trades(pair)

      assert_instance_of Hash, query
      assert_equal %w(error result), query.keys
      assert_empty query.fetch('error')

      result = query.fetch('result')
      assert_instance_of Hash, result
      assert_equal [pair, 'last'], result.keys
      assert_instance_of Array, result.first
      assert_instance_of String, result.first.first
      assert_instance_of Array, result.first.last
      assert_equal pair, result.first.first
    end
  end

  private

  def assert_get_exchange_currency_info_for(currency, alt_name, decimals,
                                            display_decimals)
    query = @query.assets(currency)['result']
    assert_equal currency, query.keys.first
    assert_equal alt_name, query[currency]['altname']
    assert_equal decimals, query[currency]['decimals']
    assert_equal display_decimals, query[currency]['display_decimals']
  end
end
