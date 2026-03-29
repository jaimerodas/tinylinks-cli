# frozen_string_literal: true

require "test_helper"

class FormatterTest < Minitest::Test
  include TestFixtures

  def setup
    @fmt = Tinylinks::Formatter.new(color: false)
  end

  def test_link_shows_title_url_and_id
    output = @fmt.link(sample_link)

    assert_includes output, "Example [#1]"
    assert_includes output, "https://example.com"
  end

  def test_link_shows_description
    output = @fmt.link(sample_link)

    assert_includes output, "An example site"
  end

  def test_link_shows_tags
    output = @fmt.link(sample_link)

    assert_includes output, "tags: ruby, rails"
  end

  def test_link_without_title_shows_untitled
    output = @fmt.link(sample_link("title" => nil))

    assert_includes output, "(untitled) [#1]"
  end

  def test_link_without_description_omits_it
    output = @fmt.link(sample_link("description" => nil))

    refute_includes output, "nil"
    lines = output.split("\n")
    assert_equal 3, lines.size  # title, url, tags
  end

  def test_link_without_tags_omits_tag_line
    output = @fmt.link(sample_link("tags" => []))

    refute_includes output, "tags:"
  end

  def test_link_list_formats_multiple_links
    data = {
      "links" => [sample_link, sample_link("id" => 2, "title" => "Second")],
      "meta" => sample_meta("total_items" => 2)
    }

    output = @fmt.link_list(data)

    assert_includes output, "Example [#1]"
    assert_includes output, "Second [#2]"
    assert_includes output, "Page 1 of 1 (2 total)"
  end

  def test_link_list_empty
    data = {"links" => [], "meta" => sample_meta("total_items" => 0, "total_pages" => 0)}

    output = @fmt.link_list(data)

    assert_includes output, "No results found"
    refute_includes output, "Page"
  end

  def test_tags_empty
    data = {"tags" => []}

    output = @fmt.tags(data)

    assert_includes output, "No results found"
  end

  def test_tags_formatting
    data = {"tags" => [{"name" => "ruby", "count" => 42}, {"name" => "rails", "count" => 15}]}

    output = @fmt.tags(data)

    assert_equal "ruby (42)\nrails (15)", output
  end

  def test_errors_formatting
    data = {"errors" => {"url" => ["has already been taken", "is invalid"]}}

    output = @fmt.errors(data)

    assert_includes output, "url has already been taken"
    assert_includes output, "url is invalid"
  end

  def test_link_colorizes_title_bold
    fmt = Tinylinks::Formatter.new(color: true)
    output = fmt.link(sample_link)

    assert_includes output, "\e[1mExample [#1]\e[0m"
  end

  def test_link_colorizes_url_cyan
    fmt = Tinylinks::Formatter.new(color: true)
    output = fmt.link(sample_link)

    assert_includes output, "\e[36mhttps://example.com\e[0m"
  end

  def test_link_colorizes_description_dim
    fmt = Tinylinks::Formatter.new(color: true)
    output = fmt.link(sample_link)

    assert_includes output, "\e[2mAn example site\e[0m"
  end

  def test_link_colorizes_tags_green
    fmt = Tinylinks::Formatter.new(color: true)
    output = fmt.link(sample_link)

    assert_includes output, "\e[32mruby, rails\e[0m"
  end

  def test_tags_colorizes_name_green
    fmt = Tinylinks::Formatter.new(color: true)
    data = {"tags" => [{"name" => "ruby", "count" => 42}]}
    output = fmt.tags(data)

    assert_includes output, "\e[32mruby\e[0m"
  end

  def test_tags_colorizes_count_dim
    fmt = Tinylinks::Formatter.new(color: true)
    data = {"tags" => [{"name" => "ruby", "count" => 42}]}
    output = fmt.tags(data)

    assert_includes output, "\e[2m(42)\e[0m"
  end

  def test_errors_colorizes_red
    fmt = Tinylinks::Formatter.new(color: true)
    data = {"errors" => {"url" => ["is invalid"]}}
    output = fmt.errors(data)

    assert_includes output, "\e[31murl is invalid\e[0m"
  end

  def test_pagination_colorizes_dim
    fmt = Tinylinks::Formatter.new(color: true)
    data = {"links" => [sample_link], "meta" => sample_meta}
    output = fmt.link_list(data)

    assert_includes output, "\e[2mPage 1 of 1 (1 total)\e[0m"
  end

  def test_link_list_empty_colorizes_dim
    fmt = Tinylinks::Formatter.new(color: true)
    data = {"links" => [], "meta" => sample_meta("total_items" => 0, "total_pages" => 0)}
    output = fmt.link_list(data)

    assert_includes output, "\e[2mNo results found\e[0m"
  end
end
