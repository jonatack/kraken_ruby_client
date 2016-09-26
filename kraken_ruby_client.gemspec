require 'kraken_ruby_client/version'

Gem::Specification.new do |s|
  s.name                  = 'kraken_ruby_client'
  s.version               = KrakenRubyClient::VERSION
  s.date                  = '2010-09-25'
  s.required_ruby_version = '>= 2.3'
  s.homepage              = 'https://rubygems.org/gems/kraken_ruby_client'
  s.author                = 'Jon Atack'
  s.email                 = 'jonnyatack@gmail.com'
  s.summary               = 'Kraken Exchange API client written in Ruby'
  s.post_install_message  = 'Thanks for installing Kraken Ruby Client!'
  s.license               = 'LGPL-3.0'
  s.files                 = `git ls-files`.split("\n")
  s.require_path          = 'lib'
  s.description           = <<-EOF
    A Kraken Exchange API wrapper for Ruby 2.3+. Emphasis on speed,
    simplicity, no meta-programming, and few dependencies. Uses the fast
    Curb gem (CUrl-RuBy, Ruby bindings for libcurl written in C) for HTTP.
  EOF

  s.add_dependency 'curb'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rake'
end
