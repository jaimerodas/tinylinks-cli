# frozen_string_literal: true

require "minitest/autorun"
require "webmock/minitest"
require "tinylinks"

WebMock.disable_net_connect!

module TestFixtures
  def sample_link(overrides = {})
    {
      "id" => 1,
      "url" => "https://example.com",
      "title" => "Example",
      "description" => "An example site",
      "tags" => ["ruby", "rails"],
      "visit_count" => 3,
      "created_at" => "2026-03-27T12:00:00Z",
      "updated_at" => "2026-03-27T12:00:00Z"
    }.merge(overrides)
  end

  def sample_meta(overrides = {})
    {
      "page" => 1,
      "per_page" => 12,
      "total_items" => 1,
      "total_pages" => 1
    }.merge(overrides)
  end

  def stub_api(method, path, status: 200, body: {}, query: nil)
    stub = stub_request(method, "#{Tinylinks::API_BASE}#{path}")
    stub = stub.with(query: query) if query
    stub.to_return(
      status: status,
      body: JSON.generate(body),
      headers: {"Content-Type" => "application/json"}
    )
  end
end
