#--
#    test/test_helper.rb
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
require 'minitest/autorun'
require 'kraken_ruby_client'

module Curl
  def self.urlalize(url, params = {})
    query_str = params.map { |k, v|
      "#{URI.join(k.to_s)}=#{CGI.escape(v.to_s)}" # <- URI.join or GGI.escape
    }.join('&')
    if url.match(/\?/) && query_str.size > 0
      "#{url}&#{query_str}"
    elsif query_str.size > 0
      "#{url}?#{query_str}"
    else
      url
    end
  end
end
