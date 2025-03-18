# frozen_string_literal: true

require "httpx"
require "concurrent"

module Wikidotrb
  module Util
    class RequestUtil
      # Sends HTTP requests to multiple URLs concurrently
      # @param client [Client] The client instance
      # @param method [String] HTTP request method ("GET" or "POST")
      # @param urls [Array<String>] List of URLs to request
      # @param return_exceptions [Boolean] Whether to return exceptions instead of raising them
      # @return [Array<HTTPX::Response, Exception>] List of responses or exceptions
      def self.request(client:, method:, urls:, return_exceptions: false)
        config = client.amc_client.config
        semaphore = Concurrent::Semaphore.new(config.semaphore_limit)

        # Create asynchronous tasks for each request
        tasks = urls.map do |url|
          Concurrent::Promises.future do
            semaphore.acquire

            begin
              case method.upcase
              when "GET"
                response = HTTPX.get(url)
              when "POST"
                response = HTTPX.post(url)
              else
                raise ArgumentError, "Invalid method"
              end

              response
            rescue StandardError => e
              e
            ensure
              semaphore.release
            end
          end
        end

        # Wait for all tasks to complete
        results = Concurrent::Promises.zip(*tasks).value!

        # Return results based on return_exceptions option
        return_exceptions ? results : results.each { |r| raise r if r.is_a?(Exception) }
      end
    end
  end
end
