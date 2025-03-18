---
layout: default
title: Example Documented Code
nav_order: 4
---

# Example Documented Code

This page shows an example of well-documented Ruby code that can be automatically processed to generate documentation.

## Example Class With Documentation

```ruby
# frozen_string_literal: true

module Wikidotrb
  module Module
    # The Client class provides methods for interacting with Wikidot sites.
    # It handles authentication, page operations, and other site interactions.
    #
    # @example Creating a new client
    #   client = Wikidotrb::Module::Client.new(site_name: "example")
    #
    # @example Authenticating the client
    #   client.authenticate(username: "user", password: "pass")
    #
    # @attr_reader [String] site_name The name of the site this client is connected to
    # @attr_reader [Boolean] logged_in Whether the client is authenticated
    # @attr_reader [User, nil] current_user The currently authenticated user, if any
    class Client
      # @return [String] The site name
      attr_reader :site_name
      
      # @return [Boolean] Whether the client is authenticated
      attr_reader :logged_in
      
      # @return [User, nil] The currently authenticated user
      attr_reader :current_user
      
      # Creates a new Client instance for interacting with a Wikidot site.
      #
      # @param [String] site_name The name of the site to connect to
      # @param [Hash] options Additional options for the client
      # @option options [Boolean] :use_ssl (true) Whether to use SSL for connections
      # @option options [Integer] :timeout (30) Connection timeout in seconds
      # @return [Client] A new client instance
      # @raise [ArgumentError] If site_name is empty or nil
      def initialize(site_name:, **options)
        raise ArgumentError, "Site name cannot be empty" if site_name.to_s.empty?
        
        @site_name = site_name
        @use_ssl = options.fetch(:use_ssl, true)
        @timeout = options.fetch(:timeout, 30)
        @logged_in = false
        @current_user = nil
      end
      
      # Authenticates the client with username and password.
      #
      # @param [String] username The username to authenticate with
      # @param [String] password The password to authenticate with
      # @return [Boolean] Whether the authentication was successful
      # @raise [AuthenticationError] If authentication fails
      # @example
      #   client.authenticate(username: "user", password: "pass")
      def authenticate(username:, password:)
        # Implementation would go here...
        # For this example, we'll just simulate a successful authentication
        @logged_in = true
        @current_user = User.new(name: username)
        true
      end
      
      # Gets the content of a page.
      #
      # @param [String] page_name The name of the page to retrieve
      # @param [Boolean] include_metadata Whether to include metadata in the response
      # @return [Page] The page object with content and metadata
      # @raise [PageNotFoundError] If the page does not exist
      # @see Page
      # @example
      #   page = client.get_page(page_name: "start")
      #   puts page.content
      def get_page(page_name:, include_metadata: true)
        # Implementation would go here...
        # For this example, we'll just return a mock page
        Page.new(
          title: page_name.capitalize,
          content: "This is the content of #{page_name}",
          metadata: include_metadata ? { created_at: Time.now } : {}
        )
      end
      
      # Edits a page with new content.
      #
      # @param [String] page_name The name of the page to edit
      # @param [String] content The new content for the page
      # @param [String, nil] title The new title for the page (optional)
      # @param [Hash] options Additional options for the edit
      # @option options [String] :comment A comment describing the edit
      # @option options [Boolean] :minor (false) Whether this is a minor edit
      # @return [Boolean] Whether the edit was successful
      # @raise [PageNotFoundError] If the page does not exist
      # @raise [AuthenticationError] If the client is not authenticated
      # @example
      #   client.edit_page(
      #     page_name: "start",
      #     content: "New content",
      #     title: "New Title",
      #     options: { comment: "Updated page", minor: true }
      #   )
      def edit_page(page_name:, content:, title: nil, **options)
        # Implementation would go here...
        # For this example, we'll just return success
        true
      end
    end
    
    # The Page class represents a page on a Wikidot site.
    #
    # @attr_reader [String] title The title of the page
    # @attr_reader [String] content The content of the page
    # @attr_reader [Hash] metadata Metadata about the page
    class Page
      # @return [String] The title of the page
      attr_reader :title
      
      # @return [String] The content of the page
      attr_reader :content
      
      # @return [Hash] Metadata about the page
      attr_reader :metadata
      
      # Creates a new Page instance.
      #
      # @param [String] title The title of the page
      # @param [String] content The content of the page
      # @param [Hash] metadata Metadata about the page
      # @return [Page] A new page instance
      def initialize(title:, content:, metadata: {})
        @title = title
        @content = content
        @metadata = metadata
      end
    end
    
    # The User class represents a user on a Wikidot site.
    #
    # @attr_reader [String] name The username
    # @attr_reader [Boolean] admin Whether the user is an admin
    class User
      # @return [String] The username
      attr_reader :name
      
      # @return [Boolean] Whether the user is an admin
      attr_reader :admin
      
      # Creates a new User instance.
      #
      # @param [String] name The username
      # @param [Boolean] admin Whether the user is an admin
      # @return [User] A new user instance
      def initialize(name:, admin: false)
        @name = name
        @admin = admin
      end
    end
  end
end
```

## Corresponding RBS Type Definitions

```ruby
module Wikidotrb
  module Module
    class Client
      attr_reader site_name: String
      attr_reader logged_in: bool
      attr_reader current_user: User?
      
      def initialize: (site_name: String, **untyped options) -> void
      def authenticate: (username: String, password: String) -> bool
      def get_page: (page_name: String, ?include_metadata: bool) -> Page
      def edit_page: (page_name: String, content: String, ?title: String?, **untyped options) -> bool
    end
    
    class Page
      attr_reader title: String
      attr_reader content: String
      attr_reader metadata: Hash[Symbol, untyped]
      
      def initialize: (title: String, content: String, ?metadata: Hash[Symbol, untyped]) -> void
    end
    
    class User
      attr_reader name: String
      attr_reader admin: bool
      
      def initialize: (name: String, ?admin: bool) -> void
    end
  end
end
```

## How Documentation is Generated

When you run `make docs`, the documentation system:

1. Runs YARD to generate documentation from the code comments
2. Processes RBS files to extract type definitions
3. Builds a Jekyll site with the documentation

The result is a comprehensive documentation site that includes:

- API reference
- Type definitions
- Examples
- Usage guides

This makes it easy for developers to understand and use your library.
