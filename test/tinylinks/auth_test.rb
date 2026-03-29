# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "time"

class AuthTest < Minitest::Test
  include TestFixtures

  def setup
    @tmpdir = Dir.mktmpdir
    @creds_file = File.join(@tmpdir, "credentials.json")
    stub_const(:CREDENTIALS_DIR, @tmpdir)
    stub_const(:CREDENTIALS_FILE, @creds_file)
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_token_returns_nil_when_no_credentials
    auth = Tinylinks::Auth.new
    assert_nil auth.token
  end

  def test_save_and_read_token
    auth = Tinylinks::Auth.new
    auth.save_token("my-token", "2099-01-01T00:00:00Z")

    assert_equal "my-token", auth.token
  end

  def test_token_returns_nil_when_expired
    auth = Tinylinks::Auth.new
    auth.save_token("old-token", "2020-01-01T00:00:00Z")

    assert_nil auth.token
  end

  def test_token_parses_iso8601_expires_at
    auth = Tinylinks::Auth.new
    auth.save_token("my-token", "2099-06-25T12:00:00Z")

    # Verify the file can be read and parsed without external requires
    raw = JSON.parse(File.read(@creds_file))
    parsed = Time.parse(raw["expires_at"])
    assert_instance_of Time, parsed
    assert_equal "my-token", auth.token
  end

  def test_logged_in_reflects_token_state
    auth = Tinylinks::Auth.new
    refute auth.logged_in?

    auth.save_token("my-token", "2099-01-01T00:00:00Z")
    assert auth.logged_in?
  end

  def test_logout_removes_credentials
    auth = Tinylinks::Auth.new
    auth.save_token("my-token", "2099-01-01T00:00:00Z")
    auth.logout

    refute auth.logged_in?
    refute File.exist?(@creds_file)
  end

  def test_login_performs_device_flow
    client = Tinylinks::Client.new
    stub_api(:post, "/device_authorizations",
      body: {
        "device_code" => "dev123",
        "verification_url" => "https://links.pati.to/device/authorize?code=dev123",
        "expires_in" => 600,
        "interval" => 0
      })
    stub_api(:post, "/device_authorizations/token",
      body: {"token" => "new-token", "expires_at" => "2099-06-25T12:00:00Z"})

    auth = Tinylinks::Auth.new(client: client)
    events = []
    token = auth.login { |event, url| events << [event, url] }

    assert_equal "new-token", token
    assert_equal [[:open_browser, "https://links.pati.to/device/authorize?code=dev123"]], events
    assert_equal "new-token", auth.token
  end

  def test_login_polls_through_pending
    client = Tinylinks::Client.new
    stub_api(:post, "/device_authorizations",
      body: {
        "device_code" => "dev123",
        "verification_url" => "https://links.pati.to/device/authorize?code=dev123",
        "expires_in" => 600,
        "interval" => 0
      })

    # First call: pending, second call: approved
    stub_request(:post, "#{Tinylinks::API_BASE}/device_authorizations/token")
      .to_return(
        {status: 400, body: '{"error":"authorization_pending"}', headers: {"Content-Type" => "application/json"}},
        {status: 200, body: '{"token":"new-token","expires_at":"2099-06-25T12:00:00Z"}', headers: {"Content-Type" => "application/json"}}
      )

    auth = Tinylinks::Auth.new(client: client)
    token = auth.login

    assert_equal "new-token", token
  end

  def test_login_raises_on_access_denied
    client = Tinylinks::Client.new
    stub_api(:post, "/device_authorizations",
      body: {"device_code" => "dev123", "verification_url" => "https://example.com", "expires_in" => 600, "interval" => 0})
    stub_api(:post, "/device_authorizations/token",
      status: 400, body: {"error" => "access_denied"})

    auth = Tinylinks::Auth.new(client: client)

    error = assert_raises(RuntimeError) { auth.login }
    assert_equal "Authorization denied by user", error.message
  end

  private

  def stub_const(const, value)
    Tinylinks::Auth.send(:remove_const, const)
    Tinylinks::Auth.const_set(const, value)
  end
end
