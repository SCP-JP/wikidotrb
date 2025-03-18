# frozen_string_literal: true

require "nokogiri"
require_relative "../common/exceptions"
require_relative "../util/requestutil"
require_relative "../util/stringutil"

module Wikidotrb
  module Module
    # Class representing a collection of users
    class UserCollection < Array
      # Get a list of user objects from a list of usernames
      # @param client [Client] The client
      # @param names [Array<String>] List of usernames
      # @param raise_when_not_found [Boolean] Whether to raise an exception when a user is not found
      # @return [UserCollection] List of user objects
      def self.from_names(client, names, raise_when_not_found = false)
        urls = names.map { |name| "https://www.wikidot.com/user:info/#{Wikidotrb::Util::StringUtil.to_unix(name)}" }

        responses = Wikidotrb::Util::RequestUtil.request(client: client, method: "GET", urls: urls)

        users = []

        responses.each do |response|
          raise response if response.is_a?(Exception)

          html = Nokogiri::HTML(response.body.to_s)

          # Check existence
          if html.at_css("div.error-block")
            raise Wikidotrb::Common::Exceptions::NotFoundException, "User not found: #{response.uri}" if raise_when_not_found

            next
          end

          # Get ID
          user_id = html.at_css("a.btn.btn-default.btn-xs")["href"].split("/").last.to_i

          # Get name
          name = html.at_css("h1.profile-title").text.strip

          # Get avatar_url
          avatar_url = "https://www.wikidot.com/avatar.php?userid=#{user_id}"

          users << User.new(
            client: client,
            id: user_id,
            name: name,
            unix_name: Wikidotrb::Util::StringUtil.to_unix(name),
            avatar_url: avatar_url
          )
        end

        new(users)
      end
    end

    # Abstract class for user objects
    class AbstractUser
      attr_accessor :client, :id, :name, :unix_name, :avatar_url, :ip, :ip_masked

      def initialize(client:, id: nil, name: nil, unix_name: nil, avatar_url: nil, ip: nil, ip_masked: nil)
        @client = client
        @id = id
        @name = name
        @unix_name = unix_name
        @avatar_url = avatar_url
        @ip = ip
        @ip_masked = ip_masked
      end
    end

    # Regular user object
    class User < AbstractUser
      attr_accessor :client, :id, :name, :unix_name, :avatar_url, :ip

      def initialize(client:, id: nil, name: nil, unix_name: nil, avatar_url: nil)
        super
      end

      # Get a user object from a username
      # @param client [Client] The client
      # @param name [String] Username
      # @param raise_when_not_found [Boolean] Whether to raise an exception when the user is not found
      # @return [User] User object
      def self.from_name(client, name, raise_when_not_found = false)
        UserCollection.from_names(client, [name], raise_when_not_found).first
      end
    end

    # Deleted user object
    class DeletedUser < AbstractUser
      def initialize(client:, id: nil)
        super(client: client, id: id, name: "account deleted", unix_name: "account_deleted", avatar_url: nil)
      end
    end

    # Anonymous user object
    class AnonymousUser < AbstractUser
      def initialize(client:, ip: nil, ip_masked: nil)
        super(client: client, id: nil, name: "Anonymous", unix_name: "anonymous", avatar_url: nil, ip: ip, ip_masked: ip_masked)
      end
    end

    # Guest user object
    class GuestUser < AbstractUser
      def initialize(client:, name:, avatar_url:)
        super(client: client, id: nil, name: name, unix_name: nil, avatar_url: avatar_url)
      end
    end

    # Wikidot system user object
    class WikidotUser < AbstractUser
      def initialize(client:)
        super(client: client, id: nil, name: "Wikidot", unix_name: "wikidot", avatar_url: nil)
      end
    end
  end
end
