# frozen_string_literal: true

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

    def server_time
      get_public 'Time'
    end

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

    private

      def get_public(method, opts = nil)
        url = @api_public_url + method
        http =
          if opts
            Curl.get(url, opts)
          else
            Curl.get(url)
          end
        parsed_response(http.body)
      end

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
        parsed_response(http.body)
      end

      def parsed_response(body)
        response = JSON.parse(body)
        response[response['error'].empty? ? 'result' : 'error']
      end

      # Kraken requires an always-increasing unsigned 64-bit integer nonce
      # using a persistent counter or the current time.
      # We generate it using a timestamp in microseconds for the higher 48 bits
      # and a pseudorandom number for the lower 16 bits.
      #
      def generate_nonce
        high_bits = (Time.now.to_f * 10_000).to_i << 16
        low_bits  = SecureRandom.random_number(2 ** 16) & 0xffff
        (high_bits | low_bits).to_s
      end

      def authenticate(url)
        hmac = OpenSSL::HMAC.digest('sha512', Base64.decode64(@api_secret), url)
        Base64.strict_encode64(hmac)
      end
  end
end
