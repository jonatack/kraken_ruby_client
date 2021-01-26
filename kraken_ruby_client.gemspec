# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'kraken_ruby_client/version'

Gem::Specification.new do |s|
  s.name                  = 'kraken_ruby_client'
  s.version               = KrakenRubyClient::VERSION
  s.date                  = '2016-09-25'
  s.required_ruby_version = '>= 2.6'
  s.homepage              = 'https://rubygems.org/gems/kraken_ruby_client'
  s.author                = 'Jon Atack'
  s.email                 = 'jon@atack.com'
  s.summary               = 'Kraken Exchange API client written in Ruby'
  s.post_install_message  = 'Thanks for installing Kraken Ruby Client!'
  s.license               = 'LGPL-3.0'
  s.files                 = `git ls-files`.split("\n")
  s.require_path          = 'lib'
  s.description           = <<-DESCRIPTION
    A Kraken Exchange API wrapper for Ruby 2.4+. Emphasis on speed,
    simplicity, no meta-programming, and few dependencies. Uses the fast
    Curb gem (CUrl-RuBy, Ruby bindings for libcurl written in C) for HTTP.

    This program comes with ABSOLUTELY NO WARRANTY.
    This is free software, and you are welcome to redistribute it
    under certain conditions; see the LICENSE file for details.
    Copyright (C) 2016-2021 Jon Atack <jon@atack.com>
  DESCRIPTION

  s.add_dependency 'curb', '~> 0.9'
  s.add_development_dependency 'bundler', '~> 2.0'
  s.add_development_dependency 'minitest', '~> 5.11'
  s.add_development_dependency 'rake', '~> 12.3'
end
