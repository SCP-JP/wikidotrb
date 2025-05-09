# frozen_string_literal: true

require "nokogiri"
require "json"
require_relative "forum_category"

module Wikidotrb
  module Module
    class ForumGroupCollection < Array
      attr_accessor :forum

      # Initialization method
      # @param forum [Forum] Forum object
      # @param groups [Array<ForumGroup>] List of groups
      def initialize(forum:, groups: [])
        super(groups)
        @forum = forum
      end

      # Get groups from site and forum
      # @param site [Site] Site object
      # @param forum [Forum] Forum object
      def self.get_groups(site:, forum:)
        groups = []

        response = site.amc_request(bodies: [{ "moduleName" => "forum/ForumStartModule", "hidden" => "true" }]).first
        body = JSON.parse(response.body)["body"]
        html = Nokogiri::HTML(body)

        html.css("div.forum-group").each do |group_info|
          group = ForumGroup.new(
            site: site,
            forum: forum,
            title: group_info.at_css("div.title").text.strip,
            description: group_info.at_css("div.description").text.strip
          )

          categories = []

          group_info.css("table tr.head~tr").each do |info|
            name = info.at_css("td.name")
            thread_count = info.at_css("td.threads").text.strip.to_i
            post_count = info.at_css("td.posts").text.strip.to_i
            last_id = info.at_css("td.last>a")
            if last_id.nil?
              thread_id = nil
              post_id = nil
            else
              thread_id, post_id = last_id["href"].match(/t-(\d+).+post-(\d+)/).captures.map(&:to_i)
            end

            category = ForumCategory.new(
              site: site,
              id: name.at_css("a")["href"].match(/c-(\d+)/)[1].to_i,
              description: name.at_css("div.description").text.strip,
              forum: forum,
              title: name.at_css("a").text.strip,
              group: group,
              threads_counts: thread_count,
              posts_counts: post_count,
              last_thread_id: thread_id,
              last_post_id: post_id
            )

            categories << category
          end

          group.categories = ForumCategoryCollection.new(forum: forum, categories: categories)

          groups << group
        end

        forum._groups = ForumGroupCollection.new(forum: forum, groups: groups)
      end

      # Search for a group by title and description
      # @param title [String] Group title
      # @param description [String] Group description
      # @return [ForumGroup, nil] Found group or nil
      def find(title: nil, description: nil)
        find do |group|
          (title.nil? || group.title == title) && (description.nil? || group.description == description)
        end
      end

      # Search for all groups matching the conditions
      # @param title [String] Group title
      # @param description [String] Group description
      # @return [Array<ForumGroup>] List of found groups
      def findall(title: nil, description: nil)
        select do |group|
          (title.nil? || group.title == title) && (description.nil? || group.description == description)
        end
      end
    end

    class ForumGroup
      attr_accessor :site, :forum, :title, :description, :categories

      def initialize(site:, forum:, title:, description:, categories: nil)
        @site = site
        @forum = forum
        @title = title
        @description = description
        @categories = categories || ForumCategoryCollection.new(forum: forum)
      end
    end
  end
end
