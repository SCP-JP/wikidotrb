# frozen_string_literal: true

require "nokogiri"
require "date"
require_relative "../common/exceptions"

module Wikidotrb
  module Module
    class ForumPostCollection < Array
      attr_accessor :thread

      # Initialization method
      # @param thread [ForumThread] Thread object
      # @param posts [Array<ForumPost>] List of post objects
      def initialize(thread:, posts: [])
        super(posts)
        @thread = thread
      end

      # Search for a post by ID
      # @param target_id [Integer] Post ID
      # @return [ForumPost, nil] ForumPost object if the post is found, nil otherwise
      def find(target_id)
        find { |post| post.id == target_id }
      end

      # Retrieve and set parent post
      # @param thread [ForumThread] Thread object
      # @param posts [Array<ForumPost>] List of post objects
      # @return [Array<ForumPost>] Updated list of posts
      def self.acquire_parent_post(thread:, posts:)
        return posts if posts.empty?

        posts.each { |post| post.parent = thread.get(post.parent_id) }
        posts
      end

      # Retrieve parent post for revisions
      def get_parent_post
        ForumPostCollection.acquire_parent_post(thread: @thread, posts: self)
      end

      # Retrieve and set post information
      # @param thread [ForumThread] Thread object
      # @param posts [Array<ForumPost>] List of post objects
      # @return [Array<ForumPost>] Updated list of posts
      def self.acquire_post_info(thread:, posts:)
        return posts if posts.empty?

        responses = thread.site.amc_request(
          bodies: posts.map do |post|
            {
              "postId" => post.id,
              "threadId" => thread.id,
              "moduleName" => "forum/sub/ForumEditPostFormModule"
            }
          end
        )

        responses.each_with_index do |response, index|
          html = Nokogiri::HTML(response.body.to_s)
          title = html.at_css("input#np-title")&.text&.strip
          source = html.at_css("textarea#np-text")&.text&.strip
          posts[index].title = title
          posts[index].source = source
        end

        posts
      end

      # Retrieve post information for revisions
      def get_post_info
        ForumPostCollection.acquire_post_info(thread: @thread, posts: self)
      end
    end

    class ForumPost
      attr_accessor :site, :id, :forum, :thread, :parent_id, :created_by, :created_at, :edited_by, :edited_at,
                    :source_text, :source_ele, :parent, :title, :source

      # Initialization method
      def initialize(site:, id:, forum:, thread: nil, parent_id: nil, created_by: nil, created_at: nil, edited_by: nil,
                     edited_at: nil, source_text: nil, source_ele: nil)
        @site = site
        @id = id
        @forum = forum
        @thread = thread
        @parent_id = parent_id
        @created_by = created_by
        @created_at = created_at
        @edited_by = edited_by
        @edited_at = edited_at
        @source_text = source_text
        @source_ele = source_ele
        @parent = nil
        @title = nil
        @source = nil
      end

      # Set parent post

      # Set title

      # Set source

      # Get the post URL
      def get_url
        "#{@thread.get_url}#post-#{@id}"
      end

      # Parent post getter method
      def parent
        ForumPostCollection.new(thread: @thread, posts: [self]).get_parent_post unless @parent
        @parent
      end

      # Title getter method
      def title
        ForumPostCollection.new(thread: @thread, posts: [self]).get_post_info unless @title
        @title
      end

      # Source getter method
      def source
        ForumPostCollection.new(thread: @thread, posts: [self]).get_post_info unless @source
        @source
      end

      # Reply to the post
      def reply(title: "", source: "")
        client = @site.client
        client.login_check
        raise Wikidotrb::Common::UnexpectedException, "Post body can not be left empty." if source == ""

        response = @site.amc_request(
          bodies: [
            {
              "parentId" => @id,
              "title" => title,
              "source" => source,
              "action" => "ForumAction",
              "event" => "savePost"
            }
          ]
        ).first
        body = JSON.parse(response.body.to_s)

        ForumPost.new(
          site: @site,
          id: body["postId"].to_i,
          forum: @forum,
          title: title,
          source: source,
          thread: @thread,
          parent_id: @id,
          created_by: client.user.get(client.username),
          created_at: DateTime.parse(body["CURRENT_TIMESTAMP"])
        )
      end

      # Edit the post
      def edit(title: nil, source: nil)
        client = @site.client
        client.login_check

        return self if title.nil? && source.nil?
        raise Wikidotrb::Common::UnexpectedException, "Post source can not be left empty." if source == ""

        begin
          response = @site.amc_request(
            bodies: [
              {
                "postId" => @id,
                "threadId" => @thread.id,
                "moduleName" => "forum/sub/ForumEditPostFormModule"
              }
            ]
          ).first
          html = Nokogiri::HTML(response.body.to_s)
          current_id = html.at_css("form#edit-post-form>input")[1].get("value").to_i

          @site.amc_request(
            bodies: [
              {
                "postId" => @id,
                "currentRevisionId" => current_id,
                "title" => title || @title,
                "source" => source || @source,
                "action" => "ForumAction",
                "event" => "saveEditPost",
                "moduleName" => "Empty"
              }
            ]
          )
        rescue Wikidotrb::Common::WikidotStatusCodeException
          return self
        end

        @edited_by = client.user.get(client.username)
        @edited_at = DateTime.now
        @title = title || @title
        @source = source || @source

        self
      end

      # Delete the post
      def destroy
        @site.client.login_check
        @site.amc_request(
          bodies: [
            {
              "postId" => @id,
              "action" => "ForumAction",
              "event" => "deletePost",
              "moduleName" => "Empty"
            }
          ]
        )
      end
    end
  end
end
