# frozen_string_literal: true
#--
#    lib/kraken_ruby_client/client.rb
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

# irb -I lib
# require 'kraken_ruby_client'; k=Kraken::Client.new

require 'base64'
require 'securerandom'
require 'curb'
require 'json'

module Kraken
  class Client
    KRAKEN_API_URL     = 'https://api.kraken.com'
    KRAKEN_API_VERSION = 0

    # Ledger/trade history calls may made once every 4 seconds.

    # All other calls may made once every 2 seconds.

    # Orders may be placed or canceled at a rate of ~1 per second.
    # They are limited by Kraken to avoid order book manipulation.

    def initialize(api_key = nil, api_secret = nil, options = {})
      @api_key         =
        "R8N2M1r0TtUvE5s22gl7Zkg0fOm9s/2HFofshrAaSUprDIFSplThxxN3"
      @api_secret      =
"IJM7sbQcSQleY38Y1mWCm0550FSfiYIXSHYShwi8FEyjlroZsXmVzAv3PXr0FH3g12xRX83OTJncj7teEIkGyQ=="
      # @api_key, @api_secret = api_key, api_secret
      base_uri              = options[:base_uri]    ||= KRAKEN_API_URL
      api_version_path      = "/#{options[:version] ||= KRAKEN_API_VERSION}"
      @api_public_url       = base_uri + api_version_path + '/public/'
      @api_private_path     =            api_version_path + '/private/'
      @api_private_url      = base_uri + @api_private_path
    end


    # Returns a new instance of <tt>ActionController::Parameters</tt>.
    # Also, sets the +permitted+ attribute to the default value of
    # <tt>ActionController::Parameters.permit_all_parameters</tt>.

    # = Public API methods
    #
    # The Date Helper primarily sets the +permitted+ attribute to
    #
    # * <tt>:include_blank</tt> - set to true if it should be possible.
    # * <tt>:discard_type</tt> - set to true if you want to discard the type.

    # = HTTP POST request for private queries involving user credentials
    #
    # +<tt>server_time</tt>
    #
    def server_time
      get_public 'Time'
    end

    # info   = info to retrieve (optional): info = all info (default).
    # aclass = asset class (optional): currency (default).
    # asset  = comma-delimited, case-insensitive asset list (optional).
    #          Examples: 'XRP' and 'USD, EUR, ETC'
    def assets(assets = nil)
      if assets
        get_public 'Assets', { 'asset': assets }
      else
        get_public 'Assets'
      end
    end

    def asset_pairs(pairs = nil)
      if pairs
        get_public 'AssetPairs', { 'pair': pairs }
      else
        get_public 'AssetPairs'
      end
    end

    def ticker(pairs = nil) # takes string of comma-delimited pairs
      get_public 'Ticker', { 'pair': pairs }
    end

    def order_book(pair = nil)
      get_public 'Depth', { 'pair': pair }
    end

    def trades(pair = nil)
      get_public 'Trades', { 'pair': pair }
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

    # Query orders info
    # URL: https://api.kraken.com/0/private/QueryOrders
    # Input:
    #   trades = include trades in output (optional, defaults to false).
    #   userref = restrict results to given user reference id (optional).
    #   txid = comma-delimited string of transaction ids to query (20 maximum).
    #
    # Result: associative array of orders info
    # <order_txid> = order info.  See Get open orders/Get closed orders.
    #
    def query_orders(txids = nil)
      if txids
        post_private 'QueryOrders', { 'txid': txids }
      else
        post_private 'QueryOrders'
      end
    end

    def trade_history(opts = {})
      post_private 'TradesHistory', opts
    end

    def query_trades(tx_ids, opts = {})
      opts['txid'] = tx_ids
      post_private 'QueryTrades', opts
    end

    def open_positions(tx_ids, opts = {})
      opts['txid'] = tx_ids
      post_private 'OpenPositions', opts
    end

    def ledgers_info(opts = {})
      post_private 'Ledgers', opts
    end

    def query_ledgers(ledger_ids, opts = {})
      opts['id'] = ledger_ids
      post_private 'QueryLedgers', opts
    end

    def trade_volume(asset_pairs, opts = {})
      opts['pair'] = asset_pairs
      post_private 'TradeVolume', opts
    end

    def add_order(opts = {})
      missing = %w(pair type ordertype volume).freeze - opts.keys.map(&:to_s)
      raise ArgumentError.new(options(missing)) unless missing.size.zero?
      post_private 'AddOrder', opts
    end

    def options(missing)
      'Unable to send the order because the following options are missing: ' +
        missing + '.'
    end

    def cancel_order(txid)
      opts = { txid: txid }
      post_private 'CancelOrder', opts
    end

    private

      # HTTP GET request for public API queries
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

      # HTTP POST request for private queries involving user credentials
      #
      def post_private(method, opts = {})
        nonce = opts['nonce'] = generate_nonce
        params = opts.map { |param| param.join('=') }.join('&')
        http = Curl.post(@api_private_url + method, params) do |http|
          http.headers['API-Key']  = @api_key
          http.headers['API-Sign'] = authenticate(
              @api_private_path + method +
              OpenSSL::Digest.new('sha256', nonce + params).digest
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
        (higher_48_bits | lower_16_bits).to_s
      end

      def authenticate(url)
        hmac = OpenSSL::HMAC.digest('sha512', Base64.decode64(@api_secret), url)
        Base64.strict_encode64(hmac)
      end
  end
end
