# frozen_string_literal: true

#--
#    Gemfile
#
#    Kraken Exchange API client written in Ruby
#    Copyright (C) 2016-2021 Jon Atack <jon@atack.com>
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
source 'https://rubygems.org'
gemspec

git_source(:github) { |repo_name| "https://github.com/#{repo_name}.git" }

# Curl Ruby for HTTP - the only runtime dependency for this gem.
gem 'curb', github: 'taf2/curb'

# Ruby Make
gem 'rake'

# Testing
gem 'minitest'
gem 'minitest-reporters'

# Minitest-focus allows you to focus on a single test without CLI arguments.
# The +focus+ class method enables running the next defined test only.
# Read more: https://github.com/seattlerb/minitest-focus
gem 'minitest-focus'

# Pretty Minitest Color Reporter.
# More info: https://github.com/danielpclark/color_pound_spec_reporter
gem 'color_pound_spec_reporter'

# Linter
gem 'rubocop'
gem 'rubocop-performance'
gem 'rubocop-minitest'
