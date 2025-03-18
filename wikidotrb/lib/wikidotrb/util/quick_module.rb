# frozen_string_literal: true

require "httpx"
require "json"

# Definition of QMCUser struct
QMCUser = Struct.new(:id, :name, keyword_init: true)

# Definition of QMCPage struct
QMCPage = Struct.new(:title, :unix_name, keyword_init: true)

class QuickModule
  # Send request
  # @param module_name [String] Module name
  # @param site_id [Integer] Site ID
  # @param query [String] Query
  # @return [Hash] JSON-parsed response result
  def self._request(module_name:, site_id:, query:)
    # Check if module name is valid
    raise ArgumentError, "Invalid module name" unless %w[MemberLookupQModule UserLookupQModule PageLookupQModule].include?(module_name)

    # Build request URL
    url = "https://www.wikidot.com/quickmodule.php?module=#{module_name}&s=#{site_id}&q=#{query}"

    # Send HTTP request
    response = HTTPX.get(url, timeout: { operation: 300 })

    # Check status code
    raise ArgumentError, "Site is not found" if response.status == 500

    # Parse JSON response
    JSON.parse(response.body.to_s)
  end

  # Search for members
  # @param site_id [Integer] Site ID
  # @param query [String] Query
  # @return [Array<QMCUser>] List of users
  def self.member_lookup(site_id:, query:)
    users = _request(module_name: "MemberLookupQModule", site_id: site_id, query: query)["users"]
    users.map { |user| QMCUser.new(id: user["user_id"].to_i, name: user["name"]) }
  end

  # Search for users
  # @param site_id [Integer] Site ID
  # @param query [String] Query
  # @return [Array<QMCUser>] List of users
  def self.user_lookup(site_id:, query:)
    users = _request(module_name: "UserLookupQModule", site_id: site_id, query: query)["users"]
    users.map { |user| QMCUser.new(id: user["user_id"].to_i, name: user["name"]) }
  end

  # Search for pages
  # @param site_id [Integer] Site ID
  # @param query [String] Query
  # @return [Array<QMCPage>] List of pages
  def self.page_lookup(site_id:, query:)
    pages = _request(module_name: "PageLookupQModule", site_id: site_id, query: query)["pages"]
    pages.map { |page| QMCPage.new(title: page["title"], unix_name: page["unix_name"]) }
  end
end
