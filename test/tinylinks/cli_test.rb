# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class CLITest < Minitest::Test
  include TestFixtures

  def setup
    WebMock.reset!
    @tmpdir = Dir.mktmpdir
    @creds_file = File.join(@tmpdir, "credentials.json")
    stub_const(:CREDENTIALS_DIR, @tmpdir)
    stub_const(:CREDENTIALS_FILE, @creds_file)

    # Write a valid token so authenticated commands work
    File.write(@creds_file, JSON.generate(token: "test-token", expires_at: "2099-01-01T00:00:00Z"))
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  # --- list ---

  def test_list_displays_links
    stub_api(:get, "/links", body: {
      "links" => [sample_link],
      "meta" => sample_meta
    })

    output = capture_cli("list")

    assert_includes output, "Example [#1]"
    assert_includes output, "https://example.com"
    assert_includes output, "Page 1 of 1"
  end

  def test_list_with_tags_filter
    stub = stub_request(:get, "#{Tinylinks::API_BASE}/links")
      .with(query: {"tags" => "ruby"})
      .to_return(status: 200, body: JSON.generate({"links" => [], "meta" => sample_meta("total_items" => 0)}),
        headers: {"Content-Type" => "application/json"})

    capture_cli("list", "--tags=ruby")

    assert_requested(stub)
  end

  def test_list_with_page
    stub = stub_request(:get, "#{Tinylinks::API_BASE}/links")
      .with(query: {"page" => "2"})
      .to_return(status: 200, body: JSON.generate({"links" => [], "meta" => sample_meta("page" => 2)}),
        headers: {"Content-Type" => "application/json"})

    capture_cli("list", "--page=2")

    assert_requested(stub)
  end

  def test_list_with_filter
    stub = stub_request(:get, "#{Tinylinks::API_BASE}/links")
      .with(query: {"filter" => "unvisited"})
      .to_return(status: 200, body: JSON.generate({"links" => [], "meta" => sample_meta("total_items" => 0)}),
        headers: {"Content-Type" => "application/json"})

    capture_cli("list", "--filter=unvisited")

    assert_requested(stub)
  end

  def test_list_with_sort
    stub = stub_request(:get, "#{Tinylinks::API_BASE}/links")
      .with(query: {"sort" => "most_visited"})
      .to_return(status: 200, body: JSON.generate({"links" => [], "meta" => sample_meta("total_items" => 0)}),
        headers: {"Content-Type" => "application/json"})

    capture_cli("list", "--sort=most_visited")

    assert_requested(stub)
  end

  def test_list_combines_filter_sort_and_tags
    stub = stub_request(:get, "#{Tinylinks::API_BASE}/links")
      .with(query: {"tags" => "ruby", "filter" => "visited", "sort" => "oldest"})
      .to_return(status: 200, body: JSON.generate({"links" => [], "meta" => sample_meta("total_items" => 0)}),
        headers: {"Content-Type" => "application/json"})

    capture_cli("list", "--tags=ruby", "--filter=visited", "--sort=oldest")

    assert_requested(stub)
  end

  def test_list_rejects_invalid_sort
    assert_raises(SystemExit) { capture_cli("list", "--sort=bogus") }
  end

  def test_list_rejects_invalid_filter
    assert_raises(SystemExit) { capture_cli("list", "--filter=bogus") }
  end

  # --- show ---

  def test_show_displays_link
    stub_api(:get, "/links/1", body: {"link" => sample_link})

    output = capture_cli("show", "1")

    assert_includes output, "Example [#1]"
    assert_includes output, "https://example.com"
    assert_includes output, "tags: ruby, rails"
    assert_includes output, "3 visits"
  end

  def test_show_not_found
    stub_api(:get, "/links/999", status: 404, body: {"error" => "not_found"})

    assert_raises(SystemExit) { capture_cli("show", "999") }
  end

  # --- add ---

  def test_add_creates_link
    stub = stub_request(:post, "#{Tinylinks::API_BASE}/links")
      .with(body: {url: "https://example.com", title: "Example", tags: ["ruby", "rails"]}.to_json)
      .to_return(status: 201, body: JSON.generate({"link" => sample_link}),
        headers: {"Content-Type" => "application/json"})

    output = capture_cli("add", "https://example.com", "--title=Example", "--tags=ruby,rails")

    assert_includes output, "Example [#1]"
    assert_requested(stub)
  end

  def test_add_with_only_url
    stub = stub_request(:post, "#{Tinylinks::API_BASE}/links")
      .with(body: {url: "https://example.com"}.to_json)
      .to_return(status: 201, body: JSON.generate({"link" => sample_link("title" => nil, "tags" => [])}),
        headers: {"Content-Type" => "application/json"})

    output = capture_cli("add", "https://example.com")

    assert_includes output, "(untitled) [#1]"
    assert_requested(stub)
  end

  def test_add_validation_error
    stub_api(:post, "/links", status: 422,
      body: {"errors" => {"url" => ["has already been taken"]}})

    assert_raises(SystemExit) { capture_cli("add", "https://example.com") }
  end

  # --- edit ---

  def test_edit_updates_link
    stub_api(:patch, "/links/1", body: {"link" => sample_link("title" => "New Title")})

    output = capture_cli("edit", "1", "--title=New Title")

    assert_includes output, "New Title [#1]"
    assert_requested(:patch, "#{Tinylinks::API_BASE}/links/1",
      body: {title: "New Title"}.to_json)
  end

  def test_edit_with_no_options_shows_error
    assert_raises(SystemExit) { capture_cli("edit", "1") }
  end

  # --- search ---

  def test_search_displays_results
    stub = stub_request(:get, "#{Tinylinks::API_BASE}/search")
      .with(query: {"q" => "ruby"})
      .to_return(status: 200, body: JSON.generate({
        "links" => [sample_link],
        "meta" => sample_meta
      }), headers: {"Content-Type" => "application/json"})

    output = capture_cli("search", "ruby")

    assert_includes output, "Example [#1]"
    assert_requested(stub)
  end

  # --- tags ---

  def test_tags_displays_list
    stub_api(:get, "/tags", body: {
      "tags" => [{"name" => "ruby", "count" => 42}, {"name" => "rails", "count" => 15}]
    })

    output = capture_cli("tags")

    assert_includes output, "ruby (42)"
    assert_includes output, "rails (15)"
  end

  def test_tags_with_sort
    stub = stub_request(:get, "#{Tinylinks::API_BASE}/tags")
      .with(query: {"sort_by" => "popularity"})
      .to_return(status: 200, body: JSON.generate({"tags" => []}),
        headers: {"Content-Type" => "application/json"})

    capture_cli("tags", "--sort=popularity")

    assert_requested(stub)
  end

  # --- untagged ---

  def test_untagged_displays_links
    stub_api(:get, "/untagged", body: {
      "links" => [sample_link("tags" => [])],
      "meta" => sample_meta
    })

    output = capture_cli("untagged")

    assert_includes output, "Example [#1]"
    assert_includes output, "Page 1 of 1"
  end

  # --- help flag ---

  def test_help_flag_shows_usage_instead_of_running_command
    output = capture_cli("untagged", "--help")

    assert_includes output, "Usage:"
    assert_includes output, "--page=N"
  end

  def test_short_help_flag_works
    output = capture_cli("list", "-h")

    assert_includes output, "Usage:"
    assert_includes output, "--tags=TAGS"
  end

  # --- version ---

  def test_version
    output = capture_cli("version")

    assert_includes output, "tinylinks #{Tinylinks::VERSION}"
  end

  # --- no-color flag ---

  def test_no_color_flag_produces_plain_output
    stub_api(:get, "/links/1", body: {"link" => sample_link})

    output = capture_cli("show", "1", "--no-color")

    assert_includes output, "Example [#1]"
    refute_includes output, "\e["
  end

  def test_no_color_flag_on_error_produces_plain_stderr
    stub_api(:post, "/links", status: 422,
      body: {"errors" => {"url" => ["is invalid"]}})

    stderr = capture_stderr do
      assert_raises(SystemExit) { capture_cli("add", "https://x.com", "--no-color") }
    end

    assert_includes stderr, "url is invalid"
    refute_includes stderr, "\e["
  end

  # --- auth required ---

  def test_command_without_login_shows_error
    File.delete(@creds_file)

    assert_raises(SystemExit) { capture_cli("list") }
  end

  private

  def capture_cli(*args)
    stdout = StringIO.new
    # Thor uses $stdout for `say`
    old_stdout = $stdout
    $stdout = stdout
    begin
      Tinylinks::CLI.start(args)
    ensure
      $stdout = old_stdout
    end
    stdout.string
  end

  def capture_stderr
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = old_stderr
  end

  def stub_const(const, value)
    Tinylinks::Auth.send(:remove_const, const)
    Tinylinks::Auth.const_set(const, value)
  end
end
