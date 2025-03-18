# frozen_string_literal: true

require "nokogiri"
require "time"

module Wikidotrb
  module Util
    module Parser
      class ODateParser
        # Parses an odate element and returns a Time object
        # @param odate_element [Nokogiri::XML::Element] The odate element
        # @return [Time] The time represented by the odate element
        # @raise [ArgumentError] If the odate element does not contain a valid unix time
        def self.parse(odate_element)
          # Parse the content if odate_element is not a Nokogiri::XML::Element
          odate_element = Nokogiri::HTML(odate_element.to_s).at_css(".odate") unless odate_element.is_a?(Nokogiri::XML::Element)

          # Raise error if element is nil or has no class attribute
          raise ArgumentError, "odate element does not contain a valid unix time" if odate_element.nil? || odate_element["class"].nil?

          # Get and process class attribute
          odate_classes = odate_element["class"].split

          # Search for class containing "time_"
          odate_classes.each do |odate_class|
            # Skip if class doesn't start with "time_"
            next unless odate_class.start_with?("time_")

            unix_time_str = odate_class.sub("time_", "")
            unix_time = unix_time_str.to_i

            # Check if unix time is within valid range
            # Wikidot supports range from -8640000000000 to 8640000000000
            min_unix_time = -8_640_000_000_000
            max_unix_time = 8_640_000_000_000
            raise Wikidotrb::Common::Exceptions::UnexpectedException, "Invalid unix time" if unix_time < min_unix_time || unix_time > max_unix_time

            return Time.at(unix_time)
          end

          # Raise error if no class containing "time_" was found
          raise ArgumentError, "odate element does not contain a valid unix time"
        end
      end
    end
  end
end
