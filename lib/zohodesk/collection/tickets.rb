# frozen_string_literal: true

require_relative 'base'

module Zohodesk
  module Collection
    # Zoho Desk tickets collection
    class Tickets < Base
      # API endpoint path
      URI_PATH = 'tickets'
    end
  end
end
