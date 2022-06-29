# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require_relative '../inflections'
require_relative '../record'

module Zohodesk
  module Collection
    # Zoho Desk Item collection
    class Base
      include Enumerable

      # @return [Array[Zohodesk::Record::Base]] array of records
      attr_reader :entries

      delegate :each, :[], to: :entries

      # @return [Class] single record item class
      def self.record_class
        Zohodesk::Record.const_get(to_s.demodulize.singularize.to_sym)
      end

      # @param response [Faraday::Response] Faraday response object from a collection request
      def initialize(response)
        @entries =
          if response.status == 204
            []
          else
            response.body['data'].map do |h|
              self.class.record_class.new(h)
            end
          end
      end
    end
  end
end
