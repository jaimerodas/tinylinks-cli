# frozen_string_literal: true

require "test_helper"

class ClientTest < Minitest::Test
  include TestFixtures

  def setup
    @client = Tinylinks::Client.new(token: "test-token")
  end

  def test_get_sends_authorization_header
    stub_api(:get, "/links", body: {"links" => []})

    @client.get("/links")

    assert_requested(:get, "#{Tinylinks::API_BASE}/links",
      headers: {"Authorization" => "Bearer test-token"})
  end

  def test_get_with_params
    stub = stub_request(:get, "#{Tinylinks::API_BASE}/links")
      .with(query: {"tags" => "ruby,rails", "page" => "2"})
      .to_return(status: 200, body: '{"links":[]}', headers: {"Content-Type" => "application/json"})

    @client.get("/links", tags: "ruby,rails", page: 2)

    assert_requested(stub)
  end

  def test_get_returns_parsed_json
    stub_api(:get, "/links/1", body: {"link" => sample_link})

    result = @client.get("/links/1")

    assert_equal "Example", result["link"]["title"]
  end

  def test_post_sends_json_body
    stub_api(:post, "/links", status: 201, body: {"link" => sample_link})

    @client.post("/links", {url: "https://example.com"})

    assert_requested(:post, "#{Tinylinks::API_BASE}/links",
      body: {url: "https://example.com"}.to_json)
  end

  def test_patch_sends_json_body
    stub_api(:patch, "/links/1", body: {"link" => sample_link("title" => "Updated")})

    @client.patch("/links/1", {title: "Updated"})

    assert_requested(:patch, "#{Tinylinks::API_BASE}/links/1",
      body: {title: "Updated"}.to_json)
  end

  def test_raises_api_error_on_failure
    stub_api(:get, "/links/999", status: 404, body: {"error" => "not_found"})

    error = assert_raises(Tinylinks::Client::ApiError) do
      @client.get("/links/999")
    end

    assert_equal 404, error.status
    assert_equal "not_found", error.body["error"]
  end

  def test_raises_api_error_on_validation_failure
    stub_api(:post, "/links", status: 422,
      body: {"errors" => {"url" => ["has already been taken"]}})

    error = assert_raises(Tinylinks::Client::ApiError) do
      @client.post("/links", {url: "https://example.com"})
    end

    assert_equal 422, error.status
    assert_includes error.body["errors"]["url"], "has already been taken"
  end

  def test_no_auth_header_without_token
    client = Tinylinks::Client.new
    stub_api(:post, "/device_authorizations", body: {"device_code" => "abc"})

    client.post("/device_authorizations")

    assert_requested(:post, "#{Tinylinks::API_BASE}/device_authorizations") { |req|
      !req.headers.key?("Authorization")
    }
  end
end
