# frozen_string_literal: true

require_relative "../common/logger"
require_relative "../common/exceptions"
require_relative "../connector/ajax"
require_relative "auth"
require_relative "private_message"
require_relative "site"
require_relative "user"

module Wikidotrb
  module Module
    class ClientUserMethods
      attr_reader :client

      def initialize(client)
        @client = client
      end

      # Get a user object from a username
      # @param name [String] Username
      # @param raise_when_not_found [Boolean] Whether to raise an exception when the user is not found
      # @return [User] User object
      def get(name, raise_when_not_found: false)
        Wikidotrb::Module::User.from_name(@client, name, raise_when_not_found)
      end

      # Get user objects from a list of usernames
      # @param names [Array<String>] List of usernames
      # @param raise_when_not_found [Boolean] Whether to raise an exception when a user is not found
      # @return [Array<User>] List of user objects
      def get_bulk(names, raise_when_not_found: false)
        Wikidotrb::Module::UserCollection.from_names(@client, names, raise_when_not_found)
      end
    end

    class ClientPrivateMessageMethods
      attr_reader :client

      def initialize(client)
        @client = client
      end

      # Send a message
      # @param recipient [User] Recipient
      # @param subject [String] Subject
      # @param body [String] Message body
      def send_message(recipient, subject, body)
        Wikidotrb::Module::PrivateMessage.send_message(
          client: @client, recipient: recipient, subject: subject, body: body
        )
      end

      # Get inbox
      # @return [PrivateMessageInbox] Inbox
      def get_inbox
        Wikidotrb::Module::PrivateMessageInbox.acquire(client: @client)
      end

      # Get sent box
      # @return [PrivateMessageSentBox] Sent box
      def get_sentbox
        Wikidotrb::Module::PrivateMessageSentBox.acquire(client: @client)
      end

      # Get messages
      # @param message_ids [Array<Integer>] List of message IDs
      # @return [PrivateMessageCollection] List of messages
      def get_messages(message_ids)
        Wikidotrb::Module::PrivateMessageCollection.from_ids(client: @client, message_ids: message_ids)
      end

      # Get a message
      # @param message_id [Integer] Message ID
      # @return [PrivateMessage] Message
      def get_message(message_id)
        Wikidotrb::Module::PrivateMessage.from_id(client: @client, message_id: message_id)
      end
    end

    class ClientSiteMethods
      attr_reader :client

      def initialize(client)
        @client = client
      end

      # Get a site object from a UNIX name
      # @param unix_name [String] Site UNIX name
      # @return [Site] Site object
      def get(unix_name)
        Wikidotrb::Module::Site.from_unix_name(client: client, unix_name: unix_name)
      end
    end

    class Client
      attr_accessor :amc_client, :is_logged_in, :username
      attr_reader :user, :private_message, :site

      # Core client
      def initialize(username: nil, password: nil, amc_config: nil, logging_level: "WARN")
        # First determine the logging level
        Wikidotrb::Common::Logger.level = logging_level

        # Initialize AMCClient
        @amc_client = Wikidotrb::Connector::AjaxModuleConnectorClient.new(site_name: "www", config: amc_config)

        # Initialize session-related variables
        @is_logged_in = false
        @username = nil

        # Login if username and password are specified
        if username && password
          Wikidotrb::Module::HTTPAuthentication.login(self, username, password)
          @is_logged_in = true
          @username = username
        end

        # Define methods
        @user = ClientUserMethods.new(self)
        @private_message = ClientPrivateMessageMethods.new(self)
        @site = ClientSiteMethods.new(self)
      end

      # Destructor
      def finalize
        return unless @is_logged_in

        Wikidotrb::Module::HTTPAuthentication.logout(self)
        @is_logged_in = false
        @username = nil
      end

      def to_s
        "Client(username=#{@username}, is_logged_in=#{@is_logged_in})"
      end

      # Login check
      def login_check
        raise Wikidotrb::Common::Exceptions::LoginRequiredException, "Login is required to execute this function" unless @is_logged_in

        nil
      end
    end
  end
end
