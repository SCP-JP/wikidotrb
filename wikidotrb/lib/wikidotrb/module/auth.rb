# frozen_string_literal: true

require "httpx"
require "uri"
require "json"
require_relative "../common/exceptions"

module Wikidotrb
  module Module
    class HTTPAuthentication
      # Login with username and password
      # @param client [Client] The client
      # @param username [String] Username
      # @param password [String] Password
      # @raise [SessionCreateException] When session creation fails
      def self.login(client, username, password)
        url = "https://www.wikidot.com/default--flow/login__LoginPopupScreen"

        # Create login request data
        request_data = {
          "login" => username,
          "password" => password,
          "action" => "Login2Action",
          "event" => "login"
        }

        response = HTTPX.post(
          url,
          headers: client.amc_client.header.get_header,
          form: request_data,
          timeout: { operation: 20 }
        )

        # Handle error response
        if response.is_a?(HTTPX::ErrorResponse)
          raise Wikidotrb::Common::Exceptions::SessionCreateException,
                "Login attempt failed due to network error: #{response.error}"
        end

        # Check status code
        unless response.status == 200
          raise Wikidotrb::Common::Exceptions::SessionCreateException,
                "Login attempt failed due to HTTP status code: #{response.status}"
        end

        # Check response body
        if response.body.to_s.include?("The login and password do not match")
          raise Wikidotrb::Common::Exceptions::SessionCreateException,
                "Login attempt failed due to invalid username or password"
        end

        # Check and parse cookies
        set_cookie_header = response.headers["set-cookie"]

        # Raise error if `set-cookie` doesn't exist or is `nil`
        raise Wikidotrb::Common::Exceptions::SessionCreateException, "Login attempt failed due to invalid cookies" if set_cookie_header.nil? || set_cookie_header.empty?

        # Get session cookie
        session_cookie = set_cookie_header.match(/WIKIDOT_SESSION_ID=([^;]+)/)

        raise Wikidotrb::Common::Exceptions::SessionCreateException, "Login attempt failed due to invalid cookies" unless session_cookie

        # Set session cookie
        client.amc_client.header.set_cookie("WIKIDOT_SESSION_ID", session_cookie[1])
      end

      # Logout
      # @param client [Client] The client
      def self.logout(client)
        begin
          client.amc_client.request(
            [{ "action" => "Login2Action", "event" => "logout", "moduleName" => "Empty" }]
          )
        rescue StandardError
          # Ignore exceptions and continue logout process
        end

        client.amc_client.header.delete_cookie("WIKIDOT_SESSION_ID")
      end
    end
  end
end
