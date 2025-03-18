# frozen_string_literal: true

require "nokogiri"
require "date"
require_relative "page_source"

module Wikidotrb
  module Module
    class PageRevisionCollection < Array
      attr_accessor :page

      # Initialization method
      # @param page [Page] Page object
      # @param revisions [Array<PageRevision>] List of revisions
      def initialize(page: nil, revisions: [])
        super(revisions)
        @page = page || revisions.first.page
      end

      # Retrieve and set sources
      # @param page [Page] Page object
      # @param revisions [Array<PageRevision>] List of revisions
      # @return [Array<PageRevision>] Updated list of revisions
      def self.acquire_sources(page:, revisions:)
        target_revisions = revisions.reject(&:source_acquired?)

        return revisions if target_revisions.empty?

        responses = page.site.amc_request(
          bodies: target_revisions.map do |revision|
            { "moduleName" => "history/PageSourceModule", "revision_id" => revision.id }
          end
        )

        responses.each_with_index do |response, index|
          body = response["body"]
          body_html = Nokogiri::HTML(body)
          target_revisions[index].source = PageSource.new(
            page: page,
            wiki_text: body_html.at_css("div.page-source").text.strip
          )
        end

        revisions
      end

      # Retrieve and set HTML
      # @param page [Page] Page object
      # @param revisions [Array<PageRevision>] List of revisions
      # @return [Array<PageRevision>] Updated list of revisions
      def self.acquire_htmls(page:, revisions:)
        target_revisions = revisions.reject(&:html_acquired?)

        return revisions if target_revisions.empty?

        responses = page.site.amc_request(
          bodies: target_revisions.map do |revision|
            { "moduleName" => "history/PageVersionModule", "revision_id" => revision.id }
          end
        )

        responses.each_with_index do |response, index|
          body = response["body"]
          # Extract HTML source
          source = body.split(
            "onclick=\"document.getElementById('page-version-info').style.display='none'\">",
            2
          )[1].split("</a>\n\t</div>\n\n\n\n", 2)[1]
          target_revisions[index].html = source
        end

        revisions
      end

      # Retrieve sources for revisions
      def get_sources
        PageRevisionCollection.acquire_sources(page: @page, revisions: self)
      end

      # Retrieve HTML for revisions
      def get_htmls
        PageRevisionCollection.acquire_htmls(page: @page, revisions: self)
      end
    end

    class PageRevision
      attr_accessor :page, :id, :rev_no, :created_by, :created_at, :comment, :source, :html

      # Initialization method
      # @param page [Page] Page object
      # @param id [Integer] Revision ID
      # @param rev_no [Integer] Revision number
      # @param created_by [AbstractUser] Creator
      # @param created_at [DateTime] Creation date and time
      # @param comment [String] Comment
      # @param source [PageSource, nil] Page source
      # @param html [String, nil] HTML source
      def initialize(page:, id:, rev_no:, created_by:, created_at:, comment:, source: nil, html: nil)
        @page = page
        @id = id
        @rev_no = rev_no
        @created_by = created_by
        @created_at = created_at
        @comment = comment
        @source = source
        @html = html
      end

      # Check if source has been retrieved
      # @return [Boolean] Whether the source has been retrieved
      def source_acquired?
        !@source.nil?
      end

      # Check if HTML has been retrieved
      # @return [Boolean] Whether the HTML has been retrieved
      def html_acquired?
        !@html.nil?
      end

      # Source getter method
      # Retrieve source if not already retrieved
      # @return [PageSource] Source object
      def source
        PageRevisionCollection.new(page: @page, revisions: [self]).get_sources unless source_acquired?
        @source
      end

      # Source setter method

      # HTML getter method
      # Retrieve HTML if not already retrieved
      # @return [String] HTML source
      def html
        PageRevisionCollection.new(page: @page, revisions: [self]).get_htmls unless html_acquired?
        @html
      end

      # HTML setter method
    end
  end
end
