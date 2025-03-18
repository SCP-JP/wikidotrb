# frozen_string_literal: true

require_relative "table/char_table"

module Wikidotrb
  module Util
    class StringUtil
      # Converts a string to Unix-style format
      # @param target_str [String] The string to be converted
      # @return [String] The converted string
      def self.to_unix(target_str)
        # NOTE: This implementation matches the legacy wikidot behavior

        # Convert special characters
        special_char_map = Wikidotrb::Table::CharTable::SPECIAL_CHAR_MAP
        target_str = target_str.chars.map { |char| special_char_map[char] || char }.join

        # Convert to lowercase
        target_str = target_str.downcase

        # Remove non-ASCII characters and replace special cases with regex
        target_str = target_str.gsub(/[^a-z0-9\-:_]/, "-")
                               .gsub(/^_/, ":_")
                               .gsub(/(?<!:)_/, "-")
                               .gsub(/^-*/, "")
                               .gsub(/-*$/, "")
                               .gsub(/-{2,}/, "-")
                               .gsub(/:{2,}/, ":")
                               .gsub(":-", ":")
                               .gsub("-:", ":")
                               .gsub("_-", "_")
                               .gsub("-_", "_")

        # Remove ':' from the beginning and end of the string
        target_str.gsub(/^:/, "").gsub(/:$/, "")
      end
    end
  end
end
