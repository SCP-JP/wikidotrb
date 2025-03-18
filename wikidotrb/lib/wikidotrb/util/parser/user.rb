# frozen_string_literal: true

require "nokogiri"
require_relative "../../module/user"

module Wikidotrb
  module Util
    module Parser
      # UserParser parses HTML elements containing user information on Wikidot pages
      # and converts them into corresponding user objects
      class UserParser
        # Parse printuser element and return a user object
        # @param client [Client] The client instance used for API communication
        # @param elem [Nokogiri::XML::Element, String, nil] The element to parse (element with printuser class),
        #   can also be a string containing HTML or the literal string "(user deleted)"
        # @return [AbstractUser, nil] The parsed user object or nil if parsing fails
        # @example Parse a user element
        #   html = '<span class="printuser"><a href="http://www.wikidot.com/user:info/username">Username</a></span>'
        #   element = Nokogiri::HTML.fragment(html).at_css('.printuser')
        #   user = UserParser.parse(client, element)
        def self.parse(client, elem)
          if elem.nil?
            return nil
          elsif deleted_user_string?(elem)
            # Handle "(user deleted)" case
            return Wikidotrb::Module::DeletedUser.new(client: client)
          elsif !elem.is_a?(Nokogiri::XML::Element)
            # Assume it is a string and parse it using Nokogiri
            parsed_doc = Nokogiri::HTML.fragment(elem.to_s)
            elem = parsed_doc.children.first
          end

          if elem["class"]&.include?("deleted")
            parse_deleted_user(client, elem)

          elsif elem["class"]&.include?("anonymous")
            parse_anonymous_user(client, elem)

          elsif gravatar_avatar?(elem)
            parse_guest_user(client, elem)

          elsif elem.text.strip == "Wikidot"
            parse_wikidot_user(client)

          else
            parse_regular_user(client, elem)
          end
        end

        # Parse a deleted user element
        # @param client [Client] The client instance used for API communication
        # @param elem [Nokogiri::XML::Element] Element with "deleted" class
        # @return [Wikidotrb::Module::DeletedUser] The deleted user object with ID if available
        def self.parse_deleted_user(client, elem)
          id = elem["data-id"].to_i
          Wikidotrb::Module::DeletedUser.new(client: client, id: id)
        end

        # Parse an anonymous user element (IP address user)
        # @param client [Client] The client instance used for API communication
        # @param elem [Nokogiri::XML::Element] Element with "anonymous" class
        # @return [Wikidotrb::Module::AnonymousUser] Anonymous user object with IP information
        def self.parse_anonymous_user(client, elem)
          masked_ip = elem.at_css("span.ip").text.gsub(/[()]/, "").strip
          ip = masked_ip # Default is the masked IP

          # Use the full IP if available from onclick attribute
          if (onclick_attr = elem.at_css("a")["onclick"])
            match_data = onclick_attr.match(/WIKIDOT.page.listeners.anonymousUserInfo\('(.+?)'\)/)
            ip = match_data[1] if match_data
          end

          Wikidotrb::Module::AnonymousUser.new(client: client, ip: ip, ip_masked: masked_ip)
        end

        # Parse a guest user element (typically with Gravatar)
        # @param client [Client] The client instance used for API communication
        # @param elem [Nokogiri::XML::Element] Element containing guest user info with Gravatar
        # @return [Wikidotrb::Module::GuestUser] Guest user object with name and avatar URL
        def self.parse_guest_user(client, elem)
          guest_name = elem.text.strip.split.first
          avatar_url = elem.at_css("img")["src"]
          Wikidotrb::Module::GuestUser.new(client: client, name: guest_name, avatar_url: avatar_url)
        end

        # Parse a special Wikidot system user
        # @param client [Client] The client instance used for API communication
        # @return [Wikidotrb::Module::WikidotUser] Wikidot system user object
        def self.parse_wikidot_user(client)
          Wikidotrb::Module::WikidotUser.new(client: client)
        end

        # Parse a regular registered Wikidot user
        # @param client [Client] The client instance used for API communication
        # @param elem [Nokogiri::XML::Element] Element containing registered user information
        # @return [Wikidotrb::Module::User, nil] Regular user object with ID, name and other details,
        #   or nil if user anchor cannot be found
        def self.parse_regular_user(client, elem)
          user_anchor = elem.css("a").last

          # Return nil if user anchor is nil
          return nil if user_anchor.nil?

          user_name = user_anchor.text.strip
          user_unix = user_anchor["href"].to_s.gsub("http://www.wikidot.com/user:info/", "")
          user_id = user_anchor["onclick"].to_s.match(/WIKIDOT.page.listeners.userInfo\((\d+)\)/)[1].to_i

          Wikidotrb::Module::User.new(
            client: client,
            id: user_id,
            name: user_name,
            unix_name: user_unix,
            avatar_url: "http://www.wikidot.com/avatar.php?userid=#{user_id}"
          )
        end

        # Check if the element contains a Gravatar avatar (used to identify guest users)
        # @param elem [Nokogiri::XML::Element] Element to check for Gravatar
        # @return [Boolean] true if the element contains a Gravatar image, false otherwise
        def self.gravatar_avatar?(elem)
          avatar_elem = elem.at_css("img")
          return false unless avatar_elem

          begin
            avatar_url = avatar_elem["src"]
            host = URI.parse(avatar_url).host
            host == "gravatar.com"
          rescue URI::InvalidURIError
            false
          end
        end

        # Check if the input is specifically the string "(user deleted)"
        # @param elem [Object] The element or string to check
        # @return [Boolean] true if the input is the string "(user deleted)", false otherwise
        def self.deleted_user_string?(elem)
          elem.is_a?(String) && elem.strip == "(user deleted)"
        end
      end
    end
  end
end
