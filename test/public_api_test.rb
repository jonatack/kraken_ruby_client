#--
#    test/test_public_api.rb
#
#    Kraken Exchange API client written in Ruby
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
require 'time'
require 'test_helper'

# To run all tests: rake or rake test
#
# To run one test file:
#   ruby -Ilib:test test/private_api_test.rb
#   or
#   rake test TEST=test/public_api_test.rb
#
# To run an individual test in a test file:
#   ruby -Ilib:test test/public_api_test.rb -n test_get_server_time
#   or
#   rake test TEST=test/public_api_test.rb TESTOPTS=--name=test_get_server_time

class PublicApiTest < Minitest::Test
  def setup
    @query ||= Kraken::Client.new
  end

  def test_get_server_time
    query = @query.server_time
    server_time         = query['result']
    server_unixtime     = server_time['unixtime']
    server_rfc1123_time = Time.parse server_time['rfc1123']
    user_time           = Time.now.getutc

    assert_equal %w(error result), query.keys
    assert_empty query['error']
    assert_equal user_time.yday, server_rfc1123_time.yday
    assert_equal user_time.hour, server_rfc1123_time.hour

    assert_kind_of Integer, server_unixtime
  end

  def test_get_assets
    query = @query.assets
    assets = %w(
      KFEE XDAO XETC XETH XLTC XNMC XREP XXBT XXDG
      XXLM XXRP XXVN ZCAD ZEUR ZGBP ZJPY ZKRW ZUSD
      )
    assert_equal %w(error result), query.keys
    assert_empty query['error']
    assert_equal assets, query['result'].keys

    assert_get_exchange_currency_info_for('ZUSD', 'USD',  4, 2)
    assert_get_exchange_currency_info_for('ZEUR', 'EUR',  4, 2)
    assert_get_exchange_currency_info_for('XXBT', 'XBT', 10, 5)
  end

  private

    def assert_get_exchange_currency_info_for(currency, alt_name, decimals,
      display_decimals)
      query_currency = @query.assets(currency)['result']
      assert_equal currency, query_currency.keys.first
      assert_equal alt_name, query_currency[currency]['altname']
      assert_equal decimals, query_currency[currency]['decimals']
      assert_equal display_decimals, query_currency[currency]['display_decimals']
    end
end
