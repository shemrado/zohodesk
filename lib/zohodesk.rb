# frozen_string_literal: true

require_relative 'zohodesk/version'
require_relative 'zohodesk/inflections'
require_relative 'zohodesk/collection'
require_relative 'zohodesk/record'
require_relative 'zohodesk/connector'

module Zohodesk
  class Error < StandardError; end
end
