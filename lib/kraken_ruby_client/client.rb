# frozen_string_literal: true
#--
#    lib/kraken_ruby_client/client.rb
#
#    Kraken Exchange API client written in Ruby
#    Copyright (C) 2017 Jon Atack
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Lesser General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Lesser General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    The author may be contacted by email at jon@atack.com.
#++

# irb -I lib
# require 'kraken_ruby_client'; k = Kraken::Client.new

require 'base64'
require 'securerandom'
require 'curb'
require 'json'

module Kraken
  class Client
    KRAKEN_API_URL     = 'https://api.kraken.com'
    KRAKEN_API_VERSION = 0

    def initialize(api_key = nil, api_secret = nil, options = {})
      @api_key, @api_secret = api_key, api_secret
      base_uri              = options[:base_uri]    ||= KRAKEN_API_URL
      api_version_path      = "/#{options[:version] ||= KRAKEN_API_VERSION}"
      @api_public_url       = base_uri + api_version_path + '/public/'
      @api_private_path     =            api_version_path + '/private/'
      @api_private_url      = base_uri + @api_private_path
    end

    # Get server time
    # URL: https://api.kraken.com/0/public/Time
    # Returns a hash with keys +error+ and +result+.
    # +result+ is an array of hashes with keys:
    #   +unixtime+  = unix timestamp
    #   +rfc1123+   = RFC 1123 time format
    #
    def server_time
      get_public 'Time'
    end

    # Get asset info
    # URL: https://api.kraken.com/0/public/Assets
    # Input:
    #   +asset+     = a comma-delimited, case-insensitive asset list string
    #                 (optional, defaults to all assets).
    #   +aclass+    = asset class (optional, defaults to +currency+).
    #                 Not useful for now; all assets have same value 'currency'.
    #
    # Returns a hash with keys +error+ and +result+.
    #   +result+ is a hash of assets with keys like ZEUR, ZUSD, XXBT, etc.
    #   Each asset is an array of the asset name and an info hash containing:
    #     +altname+          = alternate name, like EUR, USD, XBT, etc.
    #     +aclass+           = asset class (for now are all set to 'currency').
    #     +decimals+         = decimal places for record keeping.
    #     +display_decimals+ = decimal places for display (usually fewer).
    #
    def assets(assets = nil)
      if assets
        get_public 'Assets', { 'asset': assets }
      else
        get_public 'Assets'
      end
    end

    # Get tradable asset pairs
    # URL: https://api.kraken.com/0/public/AssetPairs
    # Input:
    #   +pair+      = a comma-delimited, case-insensitive list of asset pairs
    #                 (optional, defaults to all asset pairs).
    #   +info+      = info to retrieve (optional, defaults to all info).
    #                 Options:
    #                   +leverage+  = leverage info
    #                   +fees+      = fees schedule
    #                   +margin+    = margin info
    #
    # Returns a hash with keys +error+ and +result+.
    #   +result+ is a hash of asset pairs with keys like XXBTZEUR and XXBTZUSD.
    #   Each asset pair is an array of the name and a hash containing:
    #     +altname+             = alternate name, like EUR, USD, XBT, etc.
    #     +aclass_base+         = asset class of base component
    #     +base+                = asset id of base component
    #     +aclass_quote+        = asset class of quote component
    #     +quote+               = asset id of quote component
    #     +lot+                 = volume lot size
    #     +pair_decimals+       = scaling decimal places for pair
    #     +lot_decimals+        = scaling decimal places for volume
    #     +lot_multiplier+      = amount to multiply lot volume by to get
    #                             currency volume
    #     +leverage_buy+        = array of leverages available when buying
    #     +leverage_sell+       = array of leverages available when selling
    #     +fees+                = fee schedule array in
    #                             [volume, percent fee] tuples
    #     +fees_maker+          = maker fee schedule array in
    #                             [volume, percent fee] tuples if on maker/taker
    #     +fee_volume_currency+ = volume discount currency
    #     +margin_call+         = margin call level
    #     +margin_stop+         = stop-out/liquidation margin level
    def asset_pairs(pairs = nil)
      if pairs
        get_public 'AssetPairs', { 'pair': pairs }
      else
        get_public 'AssetPairs'
      end
    end

    def ticker(pairs = nil)
      get_public 'Ticker', { 'pair': pairs }
    end

    # Get open-high-low-close data
    def ohlc(pair = nil) # pair, interval (optional), since (optional)
      get_public 'OHLC', { 'pair': pair }
    end

    def order_book(pair = nil)
      get_public 'Depth', { 'pair': pair }
    end

    def trades(pair, since = nil)
      if since
        get_public 'Trades', { 'pair': pair, since: since }
      else
        get_public 'Trades', { 'pair': pair }
      end
    end

    def spread(pair = nil, opts = {})
      opts['pair'] = pair
      get_public 'Spread', opts
    end

    def balance
      post_private 'Balance'
    end

    def trade_balance(opts = {})
      post_private 'TradeBalance', opts
    end

    def open_orders(opts = {})
      post_private 'OpenOrders', opts
    end

    def closed_orders(opts = {})
      post_private 'ClosedOrders', opts
    end

    private

      # HTTP GET request for public API queries.
      #
      def get_public(method, opts = nil)
        url = @api_public_url + method
        http =
          if opts
            Curl.get(url, opts)
          else
            Curl.get(url)
          end
        JSON.parse(http.body)
      end

      # HTTP POST request for private API queries involving user credentials.
      #
      def post_private(method, opts = {})
        nonce = opts['nonce'] = generate_nonce
        params = opts.map { |param| param.join('=') }.join('&')
        http = Curl.post("#{@api_private_url}#{method}", params) do |request|
          request.headers['API-Key']  = @api_key
          request.headers['API-Sign'] = authenticate(
              "#{@api_private_path}#{method}#{
              OpenSSL::Digest.new('sha256', "#{nonce}#{params}").digest}"
            )
        end
        JSON.parse(http.body)
      end

      # Kraken requires an always-increasing unsigned 64-bit integer nonce
      # using a persistent counter or the current time.
      #
      # We generate it using a timestamp in microseconds for the higher 48 bits
      # and a pseudorandom number for the lower 16 bits.
      #
      def generate_nonce
        higher_48_bits = (Time.now.to_f * 10_000).to_i << 16
        lower_16_bits  = SecureRandom.random_number(2 ** 16) & 0xffff
        higher_48_bits | lower_16_bits
      end

      def authenticate(url)
        hmac = OpenSSL::HMAC.digest('sha512', Base64.decode64(@api_secret), url)
        Base64.strict_encode64(hmac)
      end
  end
end
