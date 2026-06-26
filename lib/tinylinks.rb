# frozen_string_literal: true

module Tinylinks
  VERSION = "0.3.0"
  BASE_URL = "https://links.pati.to"
  API_BASE = "#{BASE_URL}/api/v1"
end

require_relative "tinylinks/colorizer"
require_relative "tinylinks/client"
require_relative "tinylinks/auth"
require_relative "tinylinks/formatter"
require_relative "tinylinks/cli"
