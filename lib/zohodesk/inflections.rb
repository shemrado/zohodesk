# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'URL'
end
