# frozen_string_literal: true

require_relative "wikidotrb/version"

# Wikidotrb - Ruby library for interacting with Wikidot sites
#
# This library provides a set of tools to interact with Wikidot sites through their
# AJAX Module Connector (AMC) interface. It allows for tasks such as:
#
# * Logging in and managing authentication
# * Reading and editing pages
# * Managing forum discussions
# * Working with user accounts
# * Interacting with site settings
#
# For getting started, see {Wikidotrb::Module::Client} which is the main entry point.
#
# @example Basic usage with authentication
#   client = Wikidotrb::Module::Client.new(username: "your_username", password: "your_password")
#   site = client.site.get("your-site")
#   pages = site.pages
#
# @author The Wikidotrb Contributors
module Wikidotrb
  class Error < StandardError; end

  # Require core components
  require_relative "wikidotrb/common/decorators"
  require_relative "wikidotrb/common/exceptions"
  require_relative "wikidotrb/common/logger"

  # Require connector components
  require_relative "wikidotrb/connector/ajax"
  require_relative "wikidotrb/connector/api"

  # Require modules
  require_relative "wikidotrb/module/auth"
  require_relative "wikidotrb/module/client"
  require_relative "wikidotrb/module/forum"
  require_relative "wikidotrb/module/forum_category"
  require_relative "wikidotrb/module/forum_group"
  require_relative "wikidotrb/module/forum_post"
  require_relative "wikidotrb/module/forum_thread"
  require_relative "wikidotrb/module/page"
  require_relative "wikidotrb/module/page_revision"
  require_relative "wikidotrb/module/page_source"
  require_relative "wikidotrb/module/page_votes"
  require_relative "wikidotrb/module/private_message"
  require_relative "wikidotrb/module/site"
  require_relative "wikidotrb/module/site_application"
  require_relative "wikidotrb/module/user"

  # Require utilities
  require_relative "wikidotrb/util/parser/odate"
  require_relative "wikidotrb/util/parser/user"
  require_relative "wikidotrb/util/quick_module"
  require_relative "wikidotrb/util/requestutil"
  require_relative "wikidotrb/util/stringutil"
  require_relative "wikidotrb/util/table/char_table"
end
