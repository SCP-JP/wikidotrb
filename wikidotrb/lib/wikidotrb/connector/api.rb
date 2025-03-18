# frozen_string_literal: true

module Wikidotrb
  module Connector
    # API key object
    class APIKeys
      # Read-only attributes
      attr_reader :ro_key, :rw_key

      # Initialize
      # @param ro_key [String] Read Only Key
      # @param rw_key [String] Read-Write Key
      def initialize(ro_key:, rw_key:)
        @ro_key = ro_key
        @rw_key = rw_key
        freeze
      end
    end
  end
end
