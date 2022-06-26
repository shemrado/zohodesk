# frozen_string_literal: true

require 'json'
require 'faraday'
require 'faraday_middleware'

module Zohodesk
  # Enables access to Zoho Desk API
  class Connector
    attr_reader :org_id, :access_token, :debug

    def self.exchange_token(client_id, client_secret, code)
      JSON.parse(Faraday.post(
        'https://accounts.zoho.com/oauth/v2/token',
        {
          client_id:     client_id,
          client_secret: client_secret,
          code:          code,
          grant_type:    'authorization_code',
        },
      ).body)
    end

    def initialize(org_id, access_token, debug: false)
      @org_id       = org_id.to_s
      @access_token = access_token
      @debug        = debug
    end

    def connection
      @connection ||= Faraday.new(
        url:     'https://desk.zoho.com/api/v1/',
        headers: {
          orgId:         org_id,
          Authorization: "Zoho-oauthtoken #{access_token}",
        },
      ) do |f|
        f.request :json

        f.response :raise_error
        f.response :json
        f.response :logger if debug

        f.adapter Faraday.default_adapter
      end
    end
    alias read_connection connection

    def validate_access
      org_ids = connection
                .get('organizations')
                .body['data']
                .map { |org| org['id'].to_s }
      raise Error, "Org ID #{org_id} not found in response" unless org_ids.include?(org_id)

      true
    end
  end
end
