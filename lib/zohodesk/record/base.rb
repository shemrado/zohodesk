# frozen_string_literal: true

require 'active_support/core_ext/hash/keys'
require 'hashie/mash'
require 'hashie/extensions/mash/define_accessors'
require 'hashie/extensions/coercion'
require_relative '../inflections'

module Zohodesk
  module Record
    # Zoho Desk Item
    class Base < ::Hashie::Mash
      include Hashie::Extensions::Mash::DefineAccessors
      include Hashie::Extensions::Coercion

      class << self
        private

        def inherited(klass)
          klass.class_eval do
            # Override sub-hashes to not be instances of main class
            coerce_value klass, ->(h) { ::Hashie::Mash.new h }
          end

          super
        end
      end

      # @param hash [Hash] Zoho Desk record hash
      def initialize(hash, *_args)
        if hash.is_a?(Hash)
          super(hash.deep_transform_keys(&:underscore))
        else
          super
        end
      end
    end
  end
end
