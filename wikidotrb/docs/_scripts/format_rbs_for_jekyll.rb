#!/usr/bin/env ruby
# frozen_string_literal: true

# This script processes RBS type definitions into Jekyll-friendly pages
# It creates Markdown files with Jekyll front matter for each module/class

require 'fileutils'

# Directory paths
RBS_SOURCE_PATH = File.expand_path('../../sig', __dir__)
OUTPUT_DIR = File.expand_path('../api/pages/rbs', __dir__)

# Ensure output directory exists
FileUtils.mkdir_p(OUTPUT_DIR)

def process_rbs_files
  Dir.glob(File.join(RBS_SOURCE_PATH, '**/*.rbs')).each do |rbs_file|
    process_rbs_file(rbs_file)
  end
end

def process_rbs_file(file_path)
  content = File.read(file_path)
  namespace_blocks = extract_namespace_blocks(content)
  
  namespace_blocks.each do |namespace, block_content|
    output_path = File.join(OUTPUT_DIR, "#{namespace.gsub('::', '/')}.md")
    FileUtils.mkdir_p(File.dirname(output_path))
    
    # Create Jekyll front matter and content
    jekyll_content = "---\n"
    jekyll_content += "layout: default\n"
    jekyll_content += "title: #{namespace} Type Definitions\n"
    jekyll_content += "permalink: /api/rbs/#{namespace.gsub('::', '/')}/\n"
    jekyll_content += "nav_order: 3\n"
    jekyll_content += "parent: API Reference\n"
    jekyll_content += "---\n\n"
    
    jekyll_content += "# #{namespace} Type Definitions\n\n"
    jekyll_content += "These are the type definitions extracted from the RBS (Ruby Signature) files. " 
    jekyll_content += "RBS provides detailed type information for Ruby code.\n\n"
    
    # Add highlighted RBS code
    jekyll_content += "```ruby\n#{block_content.strip}\n```\n\n"
    
    # Add link to implementation
    jekyll_content += "## Implementation\n\n"
    jekyll_content += "To see the full implementation of this module/class, check the [source documentation](/api/yard/#{namespace.gsub('::', '/')}).\n\n"
    
    File.write(output_path, jekyll_content)
    puts "Generated RBS documentation for #{namespace} at #{output_path}"
  end
end

def extract_namespace_blocks(content)
  blocks = {}
  
  # Handle the simplest case first - the entire file as one block
  if content.strip.match?(/^module\s+([A-Za-z0-9_:]+)/) && content.count('end') <= 1
    match = content.strip.match(/^module\s+([A-Za-z0-9_:]+)/)
    namespace = match[1]
    blocks[namespace] = content
    return blocks
  end
  
  # For more complex cases, parse more carefully
  current_namespace = nil
  current_block = []
  nesting_level = 0
  
  content.each_line do |line|
    # Skip comments
    next if line.strip.start_with?('#')
    
    if (match = line.match(/^(module|class)\s+([A-Za-z0-9_:]+)/)) && nesting_level == 0
      current_namespace = match[2]
      current_block = [line]
      nesting_level = 1
    elsif nesting_level > 0
      current_block << line
      
      nesting_level += 1 if line.match?(/^(module|class)\s+/)
      nesting_level -= 1 if line.strip == 'end'
      
      if nesting_level == 0
        blocks[current_namespace] = current_block.join
        current_namespace = nil
        current_block = []
      end
    end
  end
  
  blocks
end

# Entry point
process_rbs_files if __FILE__ == $PROGRAM_NAME
