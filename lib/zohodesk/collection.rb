# frozen_string_literal: true

module Zohodesk
  # Item collections
  module Collection
    def self.collections
      constants
        .select { |c| (c != :Base) && const_get(c).is_a?(Class) }
    end
  end
end

require_relative 'collection/base'
require_relative 'collection/tickets'
