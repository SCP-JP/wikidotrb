#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yard'
require 'fileutils'

# Generate standard llms.txt file according to https://llmstxt.org/ specification
# Following the format used by Anthropic and other industry standards

module LlmsTxtGenerator
  class << self
    def generate
      # Force YARD to load from disk and parse all files
      puts "Loading YARD"
      YARD::Registry.clear
      YARD::CLI::Yardoc.new.run('--no-save', '--no-stats', 'lib/**/*.rb')
      
      # Generate in YARD output directory
      site_dir = "docs/api/yard"
      FileUtils.mkdir_p(site_dir) unless Dir.exist?(site_dir)
      
      # Generate llms.txt and llms-full.txt
      generate_standard_files(site_dir)
      
      puts "Generated llms.txt and llms-full.txt according to llmstxt.org standard"
    end

    private

    def generate_standard_files(site_dir)
      # Debugging: Print registry size
      puts "YARD Registry size: #{YARD::Registry.all.size} objects"
      
      # Get all classes and modules to document
      classes = YARD::Registry.all(:class).sort_by(&:path)
      modules = YARD::Registry.all(:module).sort_by(&:path)
      
      puts "Found #{classes.size} classes and #{modules.size} modules"
      
      # Main ruby classes excluding utility/support classes
      primary_classes = classes.select do |cls| 
        # Include main user-facing classes like Page, User, Site, Client, etc.
        class_name = cls.path.split('::').last
        important = %w[Page User Site Client Forum Thread Post Category].include?(class_name)
        
        # Exclude collection and abstract classes
        exclude = cls.path.include?("Collection") || 
                 cls.path.include?("Abstract") || 
                 cls.path.include?("Methods")
                 
        important && !exclude
      end
      
      # Main modules
      primary_modules = modules.select do |mod|
        mod.path == "Wikidotrb" || mod.path == "Wikidotrb::Module"
      end
      
      all_primary = (primary_classes + primary_modules).sort_by(&:path)
      
      puts "Selected #{all_primary.size} primary classes/modules:"
      all_primary.each {|mod| puts "  - #{mod.path}" }
      
      # Utility classes and modules
      utility_modules = modules.select do |mod|
        mod.path.start_with?("Wikidotrb::Util") || 
        mod.path.start_with?("Wikidotrb::Common") ||
        mod.path.start_with?("Wikidotrb::Connector")
      end
      
      utility_classes = classes.select do |cls|
        cls.path.include?("Util") || 
        cls.path.include?("Common") || 
        cls.path.include?("Connector")
      end
      
      all_utility = (utility_classes + utility_modules).sort_by(&:path)
      puts "Selected #{all_utility.size} utility classes/modules"
      
      # Generate llms.txt - simple format with just links
      llms_txt_content = []
      llms_txt_content << "# Wikidotrb\n\n"
      llms_txt_content << "Ruby library for interacting with Wikidot sites.\n\n"
      
      # Core Documentation section
      llms_txt_content << "## Documentation\n\n"
      llms_txt_content << "- [API Reference](/api/yard/index.html)\n"
      llms_txt_content << "- [Client Guide](/api/client.html)\n"
      
      # Main Classes section
      llms_txt_content << "\n## Main Classes\n\n"
      all_primary.each do |mod|
        path = "/api/yard/#{mod.path.gsub('::', '/')}.html"
        llms_txt_content << "- [#{mod.path}](#{path})\n"
      end
      
      # Optional section
      llms_txt_content << "\n## Utility Classes\n\n"
      
      # Utilities and support modules
      all_utility.each do |mod|
        path = "/api/yard/#{mod.path.gsub('::', '/')}.html"
        llms_txt_content << "- [#{mod.path}](#{path})\n"
      end
      
      # Generate llms-full.txt - detailed format with descriptions
      llms_full_content = []
      llms_full_content << "# Wikidotrb API Documentation\n\n"
      llms_full_content << "This document provides detailed information about the Wikidotrb API, a Ruby library for interacting with Wikidot sites.\n\n"
      
      # Document primary modules first with more details
      all_primary.each do |mod|
        path = "/api/yard/#{mod.path.gsub('::', '/')}.html"
        llms_full_content << "# #{mod.path}\n"
        llms_full_content << "Source: #{path}\n\n"
        
        # Add docstring if available
        unless mod.docstring.empty?
          llms_full_content << "#{mod.docstring.gsub(/\n\n/, "\n").strip}\n\n"
        else
          llms_full_content << "No documentation available.\n\n"
        end
        
        # Add important methods
        methods = mod.meths.reject { |m| m.visibility == :private || m.is_attribute? }
        if methods.any?
          llms_full_content << "## Methods\n\n"
          
          methods.sort_by(&:name).each do |method|
            # Only include non-inherited methods
            next if method.respond_to?(:inherited?) && method.inherited?
            next if method.name.to_s.start_with?('#')
            
            llms_full_content << "### #{method.name}\n\n"
            
            if method.docstring.empty?
              llms_full_content << "No documentation available.\n\n"
            else
              llms_full_content << "#{method.docstring.gsub(/\n\n/, "\n").strip}\n\n"
            end
          end
        else
          llms_full_content << "No methods found.\n\n"
        end
        
        llms_full_content << "\n"
      end
      
      # Write the files
      puts "Writing llms.txt with #{llms_txt_content.size} lines"
      File.write(File.join(site_dir, "llms.txt"), llms_txt_content.join)
      
      puts "Writing llms-full.txt with #{llms_full_content.size} lines"
      File.write(File.join(site_dir, "llms-full.txt"), llms_full_content.join)
    end
  end
end

LlmsTxtGenerator.generate
