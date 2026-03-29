# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module Tinylinks
  class Client
    class ApiError < StandardError
      attr_reader :status, :body

      def initialize(status, body)
        @status = status
        @body = body
        super("API error #{status}: #{body}")
      end
    end

    def initialize(token: nil)
      @token = token
    end

    def get(path, params = {})
      uri = build_uri(path, params)
      request = Net::HTTP::Get.new(uri)
      execute(request)
    end

    def post(path, body = {})
      uri = build_uri(path)
      request = Net::HTTP::Post.new(uri)
      request.body = JSON.generate(body)
      execute(request)
    end

    def patch(path, body = {})
      uri = build_uri(path)
      request = Net::HTTP::Patch.new(uri)
      request.body = JSON.generate(body)
      execute(request)
    end

    private

    def build_uri(path, params = {})
      uri = URI("#{API_BASE}#{path}")
      uri.query = URI.encode_www_form(params) unless params.empty?
      uri
    end

    def execute(request)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{@token}" if @token

      uri = request.uri
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      body = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        raise ApiError.new(response.code.to_i, body)
      end

      body
    end
  end
end
