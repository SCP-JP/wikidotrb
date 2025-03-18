# frozen_string_literal: true

require "httpx"
require_relative "forum"
require_relative "page"
require_relative "site_application"
require_relative "../common/exceptions"
require_relative "../common/decorators"

module Wikidotrb
  module Module
    class SitePagesMethods
      def initialize(site)
        @site = site
      end

      # Search for pages
      # @param kwargs [Hash] Search query parameters
      # @return [PageCollection] Collection of pages
      def search(**kwargs)
        query = SearchPagesQuery.new(**kwargs)
        PageCollection.search_pages(@site, query)
      end
    end

    class SitePageMethods
      def initialize(site)
        @site = site
      end

      # Get a page by its fullname
      # @param fullname [String] Page fullname
      # @param raise_when_not_found [Boolean] Whether to raise an exception when the page is not found
      # @return [Page, nil] Page object or nil
      def get(fullname, raise_when_not_found: true)
        res = PageCollection.search_pages(@site, Wikidotrb::Module::SearchPagesQuery.new(fullname: fullname))

        if res.empty?
          raise Wikidotrb::Common::Exceptions::NotFoundException, "Page is not found: #{fullname}" if raise_when_not_found

          return nil
        end

        res.first
      end

      # Create a page
      # @param fullname [String] Page fullname
      # @param title [String] Page title
      # @param source [String] Page source
      # @param comment [String] Comment
      # @param force_edit [Boolean] Whether to overwrite the page if it already exists
      # @return [Page] Created page object
      def create(fullname:, title: "", source: "", comment: "", force_edit: false)
        Page.create_or_edit(
          site: @site,
          fullname: fullname,
          title: title,
          source: source,
          comment: comment,
          force_edit: force_edit,
          raise_on_exists: true
        )
      end
    end

    class Site
      attr_reader :client, :id, :title, :unix_name, :domain, :ssl_supported, :pages, :page

      extend Wikidotrb::Common::Decorators

      def initialize(client:, id:, title:, unix_name:, domain:, ssl_supported:)
        @client = client
        @id = id
        @title = title
        @unix_name = unix_name
        @domain = domain
        @ssl_supported = ssl_supported

        @pages = SitePagesMethods.new(self)
        @page = SitePageMethods.new(self)
        @forum = Forum.new(site: self)
      end

      def to_s
        "Site(id=#{id}, title=#{title}, unix_name=#{unix_name})"
      end

      # Get a site object by its UNIX name
      # @param client [Client] The client
      # @param unix_name [String] Site UNIX name
      # @return [Site] Site object
      def self.from_unix_name(client:, unix_name:)
        url = "http://#{unix_name}.wikidot.com"
        timeout = { connect: client.amc_client.config.request_timeout }
        response = HTTPX.with(timeout: timeout).get(url)

        # Handle redirects
        while response.status >= 300 && response.status < 400
          url = response.headers["location"]
          response = HTTPX.with(timeout: timeout).get(url)
        end

        # If the site doesn't exist
        raise Wikidotrb::Common::Exceptions::NotFoundException, "Site is not found: #{unix_name}.wikidot.com" if response.status == 404

        # If the site exists
        source = response.body.to_s

        # id : WIKIREQUEST.info.siteId = xxxx;
        id_match = source.match(/WIKIREQUEST\.info\.siteId = (\d+);/)
        raise Wikidotrb::Common::Exceptions::UnexpectedException, "Cannot find site id: #{unix_name}.wikidot.com" if id_match.nil?

        site_id = id_match[1].to_i

        # title: title tag
        title_match = source.match(%r{<title>(.*?)</title>})
        raise Wikidotrb::Common::Exceptions::UnexpectedException, "Cannot find site title: #{unix_name}.wikidot.com" if title_match.nil?

        title = title_match[1]

        # unix_name : WIKIREQUEST.info.siteUnixName = "xxxx";
        unix_name_match = source.match(/WIKIREQUEST\.info\.siteUnixName = "(.*?)";/)
        if unix_name_match.nil?
          raise Wikidotrb::Common::Exceptions::UnexpectedException,
                "Cannot find site unix_name: #{unix_name}.wikidot.com"
        end

        unix_name = unix_name_match[1]

        # domain : WIKIREQUEST.info.domain = "xxxx";
        domain_match = source.match(/WIKIREQUEST\.info\.domain = "(.*?)";/)
        raise Wikidotrb::Common::Exceptions::UnexpectedException, "Cannot find site domain: #{unix_name}.wikidot.com" if domain_match.nil?

        domain = domain_match[1]

        # Check SSL support
        ssl_supported = response.uri.to_s.start_with?("https")

        new(
          client: client,
          id: site_id,
          title: title,
          unix_name: unix_name,
          domain: domain,
          ssl_supported: ssl_supported
        )
      end

      # Execute an AMC request for this site
      # @param bodies [Array<Hash>] List of request bodies
      # @param return_exceptions [Boolean] Whether to return exceptions
      def amc_request(bodies:, return_exceptions: false)
        client.amc_client.request(
          bodies: bodies,
          return_exceptions: return_exceptions,
          site_name: unix_name,
          site_ssl_supported: ssl_supported
        )
      end

      # Get pending membership applications for the site
      # @return [Array<SiteApplication>] List of pending applications
      def get_applications
        SiteApplication.acquire_all(site: self)
      end

      # Invite a user to the site
      # @param user [User] User to invite
      # @param text [String] Invitation text
      def invite_user(user:, text:)
        amc_request(
          bodies: [{
            action: "ManageSiteMembershipAction",
            event: "inviteMember",
            user_id: user.id,
            text: text,
            moduleName: "Empty"
          }]
        )
      rescue Wikidotrb::Common::Exceptions::WikidotStatusCodeException => e
        case e.status_code
        when "already_invited"
          raise Wikidotrb::Common::Exceptions::TargetErrorException.new(
            "User is already invited to #{unix_name}: #{user.name}"
          ), e
        when "already_member"
          raise Wikidotrb::Common::Exceptions::TargetErrorException.new(
            "User is already a member of #{unix_name}: #{user.name}"
          ), e
        else
          raise e
        end
      end

      # Get the site URL
      # @return [String] Site URL
      def get_url
        "http#{ssl_supported ? "s" : ""}://#{domain}"
      end

      # Apply decorator to `invite_user`
      login_required :invite_user
      login_required :get_applications
    end
  end
end
