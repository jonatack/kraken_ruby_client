# frozen_string_literal: true

#--
#    test/test_private_api.rb
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

class PrivateApiTest < Minitest::Test
  def setup
    @client = Kraken::Client.new
  end

  def test_generate_nonce_evaluates_to_a_51_bit_integer
    nonce = @client.send(:generate_nonce)

    assert_kind_of Integer, nonce
    assert_equal 51, Math.log2(nonce).truncate + 1
  end

  def test_generate_nonce_returns_continually_increasing_numbers
    prev_nonce = @client.send(:generate_nonce)
    next_nonce = @client.send(:generate_nonce)

    assert_operator next_nonce, :>, prev_nonce
  end

  def test_raise_error_if_api_secret_null
    @client = Kraken::Client.new

    exception = assert_raises(RuntimeError) do
      @client.withdraw(asset: 'USD', key: 'TEST_KEY', amount: 5.0)
    end

    assert_equal('API Secret is not set', exception.message)
  end

  #
  # The Kraken API_KEY and API_SECRET environment variables are required.
  #
end
