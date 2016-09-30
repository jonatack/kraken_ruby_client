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
require_relative 'test_helper'

class PublicApiTest < Minitest::Test
  def setup
    @query ||= Kraken::Client.new
  end

  def test_get_server_time
    server_time = Time.parse(@query.server_time['result']['rfc1123'])
    user_time   = Time.now.getutc
    assert_equal user_time.yday, server_time.yday
    assert_equal user_time.hour, server_time.hour
  end

  def test_get_exchange_currencies_info
    assets = %w(KFEE XDAO XETC XETH XLTC XNMC XXBT XXDG XXLM XXRP XXVN ZCAD
      ZEUR ZGBP ZJPY ZKRW ZUSD)
    assert_equal assets, @query.assets['result'].keys

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
