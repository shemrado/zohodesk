# frozen_string_literal: true

require 'json'
require 'faraday'
require 'faraday_middleware'

module Zohodesk
  # Enables access to Zoho Desk API
  class Connector
    # @return [String] Zoho Org ID
    attr_reader :org_id

    # @return [String] current access token
    attr_reader :access_token

    # @return [Boolean] debug output status
    attr_reader :debug

    class << self
      # Exchanges authorization code for the actual token
      #
      # @param client_id [String]
      #   Client ID obtained after registering the client
      # @param client_secret [String]
      #   Client secret obtained after registering the client
      # @param code [String]
      #   Authorization code obtained after generating the grant token
      #
      # @return [Hash] Hash with auth token data
      #
      # @example Returned data:
      #   {
      #     "access_token" => "1000.ec28c13539d0f637ec7fed900c907003.35525fe16cef5fb459c88469a822ed1b",
      #     "refresh_token" => "1000.1e5affc72eb0efd2659739df6d07358e.b202e424e52a5dffaad244bde2d1404a",
      #     "api_domain" => "https://www.zohoapis.com",
      #     "token_type" => "Bearer",
      #     "expires_in" => 3600
      #   }
      def exchange_token(client_id, client_secret, code)
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

      private

      def define_collection_loader(name, klass)
        define_method(:"load_#{name}") do |batch_offset: 1, batch_size: 100, **kwargs|
          response = connection.get(
            klass::URI_PATH,
            {
              from:  batch_offset,
              limit: batch_size,
            }.merge(kwargs),
          )

          klass.new(response)
        end
      end

      def define_item_loader(name, klass)
        define_method(:"load_#{name}") do |id|
          response = connection.get("#{klass::URI_PATH}/#{id}")

          klass.record_class.new(response.body)
        end
      end
    end

    # @param org_id [Integer|String] Zoho Org ID
    # @param access_token [String] OAuth access token
    # @param debug [Boolean] Enable debug output
    def initialize(org_id, access_token, debug: false)
      @org_id       = org_id.to_s
      @access_token = access_token
      @debug        = debug
    end

    # Initializes and returns Faraday connection
    #
    # @return [Faraday::Connection]
    #   Connection instance with configured base URL and headers
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

    # Validates if the token is valid and has access to the requested org
    #
    # @return [true] if we have access to the requested org
    # @raise [Zohodesk::Error] if we don't have access to the requested org
    # @raise [Faraday::ClientError] if the token is not valid at all
    def validate_access
      org_ids = connection
                .get('organizations')
                .body['data']
                .map { |org| org['id'].to_s }
      raise Error, "Org ID #{org_id} not found in response" unless org_ids.include?(org_id)

      true
    end

    # @!method load_items(batch_offset: 1, batch_size: 100, **kwargs)
    #   Load collection of items from Zoho Desk API
    #
    #   Instead of +items+, use the name of an actual collection/endpoint, like +load_tickets+
    #
    #   @param batch_offset [Integer] Index number, starting from which the items must be fetched
    #   @param batch_size [Integer] Number of items to fetch
    #   @param kwargs
    #     Other parameters that may be accepted by the endpoint, like:
    #     +load_lickets(status: 'On Hold', sortBy: 'ticketNumber')+
    #
    # @!method load_item(id)
    #   Load a single item from Zoho Desk API
    #
    #   Instead of +item+, use the name of an actual collection/endpoint, like +load_ticket+
    #
    #   @param id [Integer] Item ID
    Zohodesk::Collection.collections.each do |collection|
      multi  = collection.to_s.underscore
      single = multi.singularize
      klass  = Zohodesk::Collection.const_get(collection)

      define_collection_loader(multi, klass)
      define_item_loader(single, klass)
    end

    # Returns URL (or array of URLs) to view items in a web browser
    #
    # @param _object_name Unused
    # @param source_item [Zohodesk::Record::Base|Zohodesk::Collection::Base|Array]
    #   Items to extract URLs from
    #
    # @return [String] single item URL if single record passed
    # @return [Array] list of item URLs if collection passed
    def generate_item_url(_object_name, source_item)
      if source_item.is_a?(Zohodesk::Collection::Base)
        source_item.map(&:web_url)
      else
        source_item.web_url
      end
    end

    # Returns ID (or array of IDs) of specific item(s)
    #
    # @param _object_name Unused
    # @param source_item [Zohodesk::Record::Base|Zohodesk::Collection::Base|Array]
    #   Items to extract IDs from
    #
    # @return [String] single item ID if single record passed
    # @return [Array] list of item IDs if collection passed
    def parse_core_item_id(_object_name, source_item)
      if source_item.is_a?(Zohodesk::Collection::Base)
        source_item.map(&:id)
      else
        source_item.id
      end
    end
  end
end
