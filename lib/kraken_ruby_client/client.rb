# frozen_string_literal: true

#--
#    lib/kraken_ruby_client/client.rb
#
#    Kraken Exchange API client written in Ruby
#    Copyright (C) 2016-2021 Jon Atack <jon@atack.com>
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

require 'openssl'
require 'base64'
require 'securerandom'
require 'curb'
require 'json'
require 'kraken_ruby_client/http_errors'

module Kraken
  # irb -I lib (or) rake console
  # require 'kraken_ruby_client'
  # client = Kraken::Client.new(api_key: YOUR_KEY, api_secret: YOUR_SECRET)
  class Client
    KRAKEN_API_URL     = 'https://api.kraken.com'
    KRAKEN_API_VERSION = 0
    HTTP_SUCCESS       = 200

    def initialize(api_key: nil, api_secret: nil, options: {})
      @api_key, @api_secret = api_key, api_secret
      base_uri              = options[:base_uri] || KRAKEN_API_URL
      api_version_path      = "/#{options[:version] || KRAKEN_API_VERSION}"
      @api_public_url       = "#{base_uri}#{api_version_path}/public/"
      @api_private_path     =            "#{api_version_path}/private/"
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
        get_public 'Assets', asset: assets
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
    #
    def asset_pairs(pairs = nil)
      if pairs
        get_public 'AssetPairs', pair: pairs
      else
        get_public 'AssetPairs'
      end
    end

    def ticker(pairs = nil)
      get_public 'Ticker', pair: pairs
    end

    # Get OHLC (Open, High, Low, Close) data
    # URL: https://api.kraken.com/0/public/OHLC
    # Input:
    #   +pair+     = required asset pair for which to query OHLC data
    #   +interval+ = optional time frame interval in minutes. Defaults to 1.
    #                Permitted values: 1, 5, 15, 30, 60, 240, 1440, 10080, 21600
    #                Returns an Invalid Arguments error for other values.
    #   +since+    = optional Unix Time from when to return committed OHLC data
    #
    # Returns a hash with keys `error' and `result'.
    #   +result+ is an array containing pair name, OHLC data, and last Unixtime.
    #   The OHLC data array contains:
    #     time, open, high, low, close, VWAP, price, volume, count.
    #   The last entry in the OHLC data array is for the current, not-yet-
    #   committed frame and is always present, regardless of the value of since.
    #   +last+ is to be used as `since' when getting new committed OHLC data.
    #
    def ohlc(pair = nil, interval: 1, since: nil)
      get_public 'OHLC', pair: pair, interval: interval, since: since
    end

    def order_book(pair = nil)
      get_public 'Depth', pair: pair
    end

    def trades(pair, since = nil)
      get_public 'Trades', pair: pair, since: since
    end

    def spread(pair = nil, opts = {})
      opts['pair'] = pair
      get_public 'Spread', opts
    end

    # Create a new order (POST)
    # URL: https://api.kraken.com/0/private/AddOrder
    # Input:
    #   +pair+      required asset pair, example: XBTEUR
    #   +type+      required operation type, possible values: buy/sell
    #   +volume+    required order size
    #   +ordertype+ required, possible values:
    #     market
    #     limit                   price = limit price
    #     stop-loss               price = stop loss price
    #     take-profit             price = take profit price
    #     stop-loss-profit        price = stop loss price,
    #                             price2 = take profit price)
    #     stop-loss-profit-limit  price = stop loss price,
    #                             price2 = take profit price
    #     stop-loss-limit         price = stop loss trigger price,
    #                             price2 = triggered limit price
    #     take-profit-limit       price = take profit trigger price,
    #                             price2 = triggered limit price
    #     trailing-stop           price = trailing stop offset
    #     trailing-stop-limit     price = trailing stop offset,
    #                             price2 = triggered limit offset
    #     stop-loss-and-limit     price = stop loss price
    #                             price2 = limit price
    #     settle-position
    #   +price+     price (optional, dependant on ordertype)
    #   +price2+    secondary price (optional, dependent on ordertype)
    #   +leverage+  amount of leverage desired (optional, default = none)
    #
    # Examples:
    #
    # require 'kraken_ruby_client'
    # client = Kraken::Client.new(api_key: YOUR_KEY, api_secret: YOUR_SECRET)
    #
    # Market buy order:
    #
    #   client.add_order(pair: 'XBTEUR', type: 'buy', ordertype: 'market',
    #     volume: 0.5)
    #
    # Limit buy order:
    #
    #   client.add_order(pair: 'XBTUSD', type: 'buy', ordertype: 'limit',
    #     volume: 1.25, price: 5000)
    #
    # Margin sell order (short):
    #
    #   client.add_order(pair: 'DASHEUR', type: 'sell', ordertype: 'market',
    #     volume: 1, leverage: 2)
    #
    def add_order(opts = {})
      missing_args = add_order_required_args - opts.keys.map(&:to_s)
      raise ArgumentError, order_err_msg(missing_args) if missing_args.any?

      post_private 'AddOrder', opts
    end

    def add_order_required_args
      %w(pair type volume ordertype).freeze
    end
    
    def edit_order(opts = {})
      missing_args = edit_order_required_args - opts.keys.map(&:to_s)
      raise ArgumentError, order_err_msg(missing_args) if missing_args.any?

      post_private 'EditOrder', opts
    end
    
    def edit_order_required_args
      %w(txid pair).freeze
    end

    def order_err_msg(missing_args)
      "the following required arguments are missing: #{missing_args.join(', ')}"
    end

    # Cancel order having txn id
    #
    def cancel_order(txid)
      post_private 'CancelOrder', txid: txid
    end

    def balance
      post_private 'Balance'
    end

    def balance_ex
      post_private 'BalanceEx'
    end

    def trade_balance(opts = {})
      post_private 'TradeBalance', opts
    end

    # Retrieve information about trades/fills.
    # 50 results are returned at a time, the most recent by default.
    # https://docs.kraken.com/rest/#operation/getTradeHistory
    def trades_history(opts = {})
      post_private 'TradesHistory', opts
    end

    # Retrieve information about specific trades/fills.
    # https://docs.kraken.com/rest/#operation/getTradesInfo
    def query_trades(opts = {})
      post_private 'QueryTrades', opts
    end

    # Fetch trade volume (POST)
    # URL: https://api.kraken.com/0/private/TradeVolume
    # Input:
    #   +pair+     [string] comma-delimited list of asset pairs (optional)
    #   +fee-info+ [boolean] whether or not to include fee info (optional)
    #
    # Returns a hash with keys `error' and `result'.
    #   +result+ is a hash of hashes containing keys:
    #            currency, volume, fees, fees_maker.
    #   currency   = volume currency
    #   volume     = current discount volume
    #   fees       = array of asset pairs and fee tier info (if requested)
    #     fee        = current fee in percent
    #     minfee     = minimum fee for pair (if not fixed fee)
    #     maxfee     = maximum fee for pair (if not fixed fee)
    #     nextfee    = next tier's fee for pair
    #                  (if not fixed fee. nil if at lowest fee tier)
    #     nextvolume = volume level of next tier
    #                  (if not fixed fee. nil if at lowest fee tier)
    #     tiervolume = volume level of current tier
    #                  (if not fixed fee. nil if at lowest fee tier)
    #   fees_maker = array of asset pairs and maker fee tier info (if requested)
    #                for any pairs on maker/taker schedule
    #     fee        = current fee in percent
    #     minfee     = minimum fee for pair (if not fixed fee)
    #     maxfee     = maximum fee for pair (if not fixed fee)
    #     nextfee    = next tier's fee for pair
    #                  (if not fixed fee, nil if at lowest fee tier)
    #     nextvolume = volume level of next tier
    #                  (if not fixed fee, nil if at lowest fee tier)
    #     tiervolume = volume level of current tier
    #                  (if not fixed fee, nil if at lowest fee tier)
    #
    # Note: If an asset pair is on a maker/taker fee schedule, the taker side is
    # given in "fees" and maker side in "fees_maker". For pairs not on
    # maker/taker, they will only be given in "fees".
    #
    # Examples:
    #
    # require 'kraken_ruby_client'
    # client = Kraken::Client.new(api_key: YOUR_KEY, api_secret: YOUR_SECRET)
    # client.trade_volume
    # client.trade_volume(pair: 'XBTEUR, etcusd, xbteth')
    # client.trade_volume(pair: 'XBTEUR', 'fee-info': true)
    #
    def trade_volume(opts = {})
      post_private 'TradeVolume', opts
    end

    # Fetch open orders (POST)
    # URL: https://api.kraken.com/0/private/OpenOrders
    # Input:
    #   +trades+    predicate to include trades (optional, default `false`)
    #   +userref+   restrict results to given user reference id (optional)
    #
    # Examples:
    #
    # require 'kraken_ruby_client'
    # client = Kraken::Client.new(api_key: YOUR_KEY, api_secret: YOUR_SECRET)
    # open_orders = client.open_orders.dig('result', 'open')
    #
    # Display all open orders from newest to oldest:
    #
    #   open_orders.each { |o| puts "#{o.first}, #{o.last.dig('descr')}" }
    #
    # Display all open orders by descending price:
    #
    #   open_orders
    #   .sort_by { |o| o.last.dig('descr', 'price').to_i }
    #   .reverse
    #   .each { |o| puts "#{o.first}, #{o.last.dig('descr')}" }
    #
    # Return most recent open order and total number of open orders:
    #
    #   open_orders.first
    #   open_orders.count
    #
    # Return all open orders for a pair:
    #
    #   pair = 'ETHEUR'
    #   open_orders.select { |_, v| v.dig('descr', 'pair') == pair }
    #
    # Return most recent open order for a pair:
    #
    #   open_orders.detect { |_, v| v.dig('descr', 'pair') == pair }
    #
    def open_orders(opts = {})
      post_private 'OpenOrders', opts
    end

    # Fetch closed orders (POST)
    # URL: https://api.kraken.com/0/private/ClosedOrders
    # Input:
    #   +trades+    predicate to include trades (optional, default `false`)
    #   +userref+   restrict results to given user reference id (optional)
    #   +start+     start UNIX timestamp or order txid (optional. exclusive)
    #   +end+       end UNIX timestamp or order txid (optional. inclusive)
    #   +ofs+       result offset
    #   +closetime+ which time to use, optional: open, close, or both (default)
    # Note: Times given by order txids are more accurate than UNIX timestamps.
    #       If an order txid is given, the order's open time is used.
    #
    # Examples:
    #
    # require 'kraken_ruby_client'
    # client = Kraken::Client.new(api_key: YOUR_KEY, api_secret: YOUR_SECRET)
    # closed_orders = client.closed_orders.dig('result', 'closed')
    #
    # Return most recent closed order and total number of closed orders:
    #
    #   closed_orders.first
    #   closed_orders.count
    #
    # Return all closed orders for a pair:
    #
    #   pair = 'ZECEUR'
    #   closed_orders.select { |_, v| v.dig('descr', 'pair') == pair }
    #
    # Return most recent closed order for a pair:
    #
    #   closed_orders.detect { |_, v| v.dig('descr', 'pair') == pair }
    #
    def closed_orders(opts = {})
      post_private 'ClosedOrders', opts
    end

    # Query orders (POST)
    # URL: https://api.kraken.com/0/private/QueryOrders
    # Input:
    #   +trades+    predicate to include trades (optional, default `false`)
    #   +userref+   restrict results to given user reference id (optional)
    #   +txid+      comma-delimited list of transaction IDs to query info about
    #               (20 maximum)
    #
    # Examples:
    #
    # require 'kraken_ruby_client'
    # client = Kraken::Client.new(api_key: YOUR_KEY, api_secret: YOUR_SECRET)
    #
    # Return orders based on a transaction id
    #
    #   queried_orders = client.query_orders(txid: txid)
    #
    def query_orders(opts = {})
      post_private 'QueryOrders', opts
    end

    # Fetch ledgers by asset(s) (POST)
    # URL: https://api.kraken.com/0/private/Ledgers
    # Input:
    #   +asset+     comma-delimited list of asset names to get info on
    #               (optional)
    #   +aclass+    asset class (optional): currency (default) or asset
    #   +type+      type of ledger to retrieve (optional), accepted string
    #               values: all (default), deposit, withdrawal, trade, margin
    #   +start+     start UNIX timestamp or order txid (optional; exclusive)
    #   +end+       end UNIX timestamp or order txid (optional; inclusive)
    #   +ofs+       result offset
    #
    # Note: Times given by order txids are more accurate than UNIX timestamps.
    #       If an order txid is given, the order's open time is used.
    #
    # Examples:
    #
    # require 'kraken_ruby_client'
    # client = Kraken::Client.new(api_key: YOUR_KEY, api_secret: YOUR_SECRET)
    #
    # Return ledgers based on a particular asset
    #
    #   ledgers = client.ledgers(asset: "AAVE")
    #
    def ledgers(opts = {})
      post_private 'Ledgers', opts
    end

    # Query ledgers by ledger id(s) (POST)
    # URL: https://api.kraken.com/0/private/QueryLedgers
    # Input:
    #   +id+        comma-delimited list of ledger IDs to query info about
    #               (20 maximum)
    #   +trades+    predicate to include trades (optional, default `false`)
    #
    # Examples:
    #
    # require 'kraken_ruby_client'
    # client = Kraken::Client.new(api_key: YOUR_KEY, api_secret: YOUR_SECRET)
    #
    # Return ledger info on a specific ledger
    #
    #   ledgers = client.ledgers(id: "LX4A-QQQ")
    #
    def query_ledgers(opts = {})
      post_private 'QueryLedgers', opts
    end

    # Get deposit methods (POST)
    #
    # Examples:
    #
    # client.deposit_methods(asset: :xxbt)
    #
    def deposit_methods(opts = {})
      post_private 'DepositMethods', opts
    end

    # Get deposit addresses (POST)
    # Input:
    #   aclass = asset class (optional):
    #     currency (default)
    #   asset = asset being deposited
    #   method = name of the deposit method
    #   new = whether or not to generate a new address (optional, default false)
    #
    # Result: associative array of deposit addresses:
    #   address = deposit address
    #   expiretm = expiration time in unix timestamp, or 0 if not expiring
    #   new = whether or not address has ever been used
    #
    # Examples:
    #
    # client.deposit_addresses(asset: 'xxbt', method: 'Bitcoin', new: true)
    #
    def deposit_addresses(opts = {})
      post_private 'DepositAddresses', opts
    end

    # Get deposit status (POST)
    #
    # Example:
    #
    # client.deposit_status(asset: :xxbt, method: 'Bitcoin')
    #
    def deposit_status(opts = {})
      post_private 'DepositStatus', opts
    end

    # Withdraw info (POST)
    #
    # Example:
    #
    # client.withdraw_info(asset: :zusd, key: 'Bank account name', amount: 10)
    #
    def withdraw_info(opts = {})
      post_private 'WithdrawInfo', opts
    end

    # Withdraw status (POST)
    #
    # Example:
    #
    # client.withdraw_status(asset: :zeur)
    #
    def withdraw_status(opts = {})
      post_private 'WithdrawStatus', opts
    end

    # Withdraw funds (POST)
    # URL: https://api.kraken.com/0/private/Withdraw
    # Input:
    #   +aclass+    asset class (optional)
    #   +asset+     asset being withdrawn
    #   +key+       withdrawal key name, as set up on your account
    #   +amount+    amount to withdraw, including fees
    #
    # Examples:
    #
    # require 'kraken_ruby_client'
    # client = Kraken::Client.new(api_key: YOUR_KEY, api_secret: YOUR_SECRET)
    # client.withdraw(asset: :zusd, key: 'Bank account name', amount: 10)
    #
    def withdraw(opts = {})
      post_private 'Withdraw', opts
    end

    # Request withdrawal cancellation (POST)
    #
    # Input:
    #   aclass = asset class (optional):
    #     currency (default)
    #   asset = asset being withdrawn
    #   refid = withdrawal reference id
    #
    # Result: true on success
    #
    # Note: Cancellation cannot be guaranteed. This will put in a cancelation
    # request. Depending upon how far along the withdrawal process is, it may
    # not be possible to cancel the withdrawal.
    #
    def withdraw_cancel(opts = {})
      post_private 'WithdrawCancel', opts
    end

    private

    # HTTP GET request for public API queries.
    #
    def get_public(method, opts = {})
      url = "#{@api_public_url}#{method}"
      http = Curl.get(url, opts)

      parse_response(http)
    end

    # HTTP POST request for private API queries involving user credentials.
    #
    def post_private(method, opts = {})
      url = "#{@api_private_url}#{method}"
      nonce = opts['nonce'] = generate_nonce
      params = opts.map { |param| param.join('=') }.join('&')

      http = Curl.post(url, params) do |request|
        request.headers = {
          'api-key'  => @api_key,
          'api-sign' => authenticate(auth_url(method, nonce, params))
        }
      end

      parse_response(http)
    end

    def parse_response(http)
      if http.response_code == HTTP_SUCCESS
        JSON.parse(http.body)
      else
        http.status
      end
    rescue *KrakenRubyClient::HTTP_ERRORS => e
      "Error #{e.inspect}"
    end

    # Generate a continually-increasing unsigned 51-bit integer nonce from the
    # current Unix Time.
    #
    def generate_nonce
      ((Time.now.to_f * 1_000_000).to_i << 10).to_s
    end

    def auth_url(method, nonce, params)
      data = "#{nonce}#{params}"
      @api_private_path + method + Digest::SHA256.digest(data)
    end

    def authenticate(url)
      raise 'API Key is not set' unless @api_key
      raise 'API Secret is not set' unless @api_secret

      hmac = OpenSSL::HMAC.digest('sha512', Base64.decode64(@api_secret), url)
      Base64.strict_encode64(hmac)
    end
  end
end
