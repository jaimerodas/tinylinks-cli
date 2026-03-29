# frozen_string_literal: true

require "test_helper"

class FormatterTest < Minitest::Test
  include TestFixtures

  def setup
    @fmt = Tinylinks::Formatter.new
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

    assert_includes output, "Page 1 of 0 (0 total)"
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
end
