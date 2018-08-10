#--
#    test/test_private_api.rb
#
#    Kraken Exchange API client written in Ruby
#    Copyright (C) 2018 Jon Atack
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
  #
  # The Kraken API_KEY and API_SECRET environment variables are required.
  #
end
