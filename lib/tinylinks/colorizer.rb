# frozen_string_literal: true

module Tinylinks
  class Colorizer
    def initialize(enabled: true)
      @enabled = enabled
    end

    def bold(text)  = wrap(text, 1)
    def dim(text)   = wrap(text, 2)
    def red(text)   = wrap(text, 31)
    def green(text) = wrap(text, 32)
    def cyan(text)  = wrap(text, 36)

    private

    def wrap(text, code)
      return text unless @enabled
      "\e[#{code}m#{text}\e[0m"
    end
  end
end
