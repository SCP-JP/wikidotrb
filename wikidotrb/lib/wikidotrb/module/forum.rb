# frozen_string_literal: true

require_relative "forum_category"
require_relative "forum_group"
require_relative "forum_thread"

module Wikidotrb
  module Module
    class ForumCategoryMethods
      # Initialization method
      # @param forum [Forum] Forum object
      def initialize(forum)
        @forum = forum
      end

      # Get category by ID
      # @param id [Integer] Category ID
      # @return [ForumCategory] Updated category
      def get(id)
        category = ForumCategory.new(
          site: @forum.site,
          id: id,
          forum: @forum
        )
        category.update
      end
    end

    class ForumThreadMethods
      # Initialization method
      # @param forum [Forum] Forum object
      def initialize(forum)
        @forum = forum
      end

      # Get thread by ID
      # @param id [Integer] Thread ID
      # @return [ForumThread] Updated thread
      def get(id)
        thread = ForumThread.new(
          site: @forum.site,
          id: id,
          forum: @forum
        )
        thread.update
      end
    end

    class Forum
      attr_accessor :site, :_groups, :_categories

      # Initialization method
      # @param site [Site] Site object
      def initialize(site:)
        @site = site
        @name = "Forum"
        @_groups = nil
        @_categories = nil
        @category = ForumCategoryMethods.new(self)
        @thread = ForumThreadMethods.new(self)
      end

      # Get category method object
      # @return [ForumCategoryMethods] Category method
      attr_reader :category

      # Get thread method object
      # @return [ForumThreadMethods] Thread method
      attr_reader :thread

      # Get forum URL
      # @return [String] Forum URL
      def get_url
        "#{@site.get_url}/forum/start"
      end

      # Group property
      # @return [ForumGroupCollection] Group collection
      def groups
        ForumGroupCollection.get_groups(site: @site, forum: self) if @_groups.nil?
        @_groups
      end

      # Category property
      # @return [ForumCategoryCollection] Category collection
      def categories
        ForumCategoryCollection.get_categories(site: @site, forum: self) if @_categories.nil?
        @_categories
      end
    end
  end
end
