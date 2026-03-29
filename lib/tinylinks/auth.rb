# frozen_string_literal: true

require "json"
require "fileutils"
require "time"

module Tinylinks
  class Auth
    CREDENTIALS_DIR = File.join(Dir.home, ".config", "tinylinks")
    CREDENTIALS_FILE = File.join(CREDENTIALS_DIR, "credentials.json")

    def initialize(client: Client.new)
      @client = client
    end

    def login
      grant = @client.post("/device_authorizations")
      yield(:open_browser, grant["verification_url"]) if block_given?

      poll_for_token(grant["device_code"], grant["interval"], grant["expires_in"])
    end

    def token
      return nil unless File.exist?(CREDENTIALS_FILE)

      data = JSON.parse(File.read(CREDENTIALS_FILE))
      expires_at = Time.parse(data["expires_at"]) if data["expires_at"]

      if expires_at && expires_at <= Time.now
        nil
      else
        data["token"]
      end
    end

    def save_token(token, expires_at)
      FileUtils.mkdir_p(CREDENTIALS_DIR)
      File.write(CREDENTIALS_FILE, JSON.generate(token: token, expires_at: expires_at))
    end

    def logged_in?
      !token.nil?
    end

    def logout
      File.delete(CREDENTIALS_FILE) if File.exist?(CREDENTIALS_FILE)
    end

    private

    def poll_for_token(device_code, interval, expires_in)
      deadline = Time.now + expires_in

      loop do
        sleep(interval)
        raise "Authorization expired" if Time.now >= deadline

        response = @client.post("/device_authorizations/token", {device_code: device_code})
        save_token(response["token"], response["expires_at"])
        return response["token"]
      rescue Client::ApiError => e
        case e.body["error"]
        when "authorization_pending"
          next
        when "access_denied"
          raise "Authorization denied by user"
        when "expired_token"
          raise "Authorization expired"
        else
          raise
        end
      end
    end
  end
end
