# frozen_string_literal: true

require "test_helper"

class ColorizerTest < Minitest::Test
  def setup
    @color = Tinylinks::Colorizer.new(enabled: true)
    @plain = Tinylinks::Colorizer.new(enabled: false)
  end

  def test_bold_wraps_with_ansi_code
    assert_equal "\e[1mhello\e[0m", @color.bold("hello")
  end

  def test_dim_wraps_with_ansi_code
    assert_equal "\e[2mhello\e[0m", @color.dim("hello")
  end

  def test_red_wraps_with_ansi_code
    assert_equal "\e[31mhello\e[0m", @color.red("hello")
  end

  def test_green_wraps_with_ansi_code
    assert_equal "\e[32mhello\e[0m", @color.green("hello")
  end

  def test_cyan_wraps_with_ansi_code
    assert_equal "\e[36mhello\e[0m", @color.cyan("hello")
  end

  def test_disabled_bold_returns_plain_text
    assert_equal "hello", @plain.bold("hello")
  end

  def test_disabled_dim_returns_plain_text
    assert_equal "hello", @plain.dim("hello")
  end

  def test_disabled_red_returns_plain_text
    assert_equal "hello", @plain.red("hello")
  end

  def test_disabled_green_returns_plain_text
    assert_equal "hello", @plain.green("hello")
  end

  def test_disabled_cyan_returns_plain_text
    assert_equal "hello", @plain.cyan("hello")
  end
end
