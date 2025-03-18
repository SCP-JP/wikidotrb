#!/usr/bin/env ruby
# frozen_string_literal: true

# This script processes YARD documentation output into Jekyll-friendly pages
# It creates Markdown files with Jekyll front matter for each class and module

require 'fileutils'
require 'json'
require 'yard'

# Directory paths
YARD_DIR = File.expand_path('../api/yard', __dir__)
OUTPUT_DIR = YARD_DIR # Output markdown files to the same directory as HTML files

# Ensure output directory exists
FileUtils.mkdir_p(OUTPUT_DIR)

def generate_pages
  # Generate YARD documentation directly
  YARD::CLI::Yardoc.run('--output-dir', YARD_DIR, '--title', 'Wikidotrb Documentation')
  
  # Process each class, module, and namespace
  YARD::Registry.all(:class, :module).each do |object|
    generate_page_for_object(object)
  end
end

def generate_page_for_object(object)
  # Create output path
  path = object.path.gsub('::', '/')
  output_path = File.join(OUTPUT_DIR, "#{path}.md")
  FileUtils.mkdir_p(File.dirname(output_path))
  
  # Get object methods
  instance_methods = object.meths(scope: :instance).reject { |m| m.visibility == :private }
  class_methods = object.meths(scope: :class).reject { |m| m.visibility == :private }
  
  # Create Jekyll front matter and content
  content = "---\n"
  content += "layout: default\n"
  content += "title: #{object.name}\n"
  content += "parent: #{object.namespace.name}\n" if object.namespace && object.namespace != YARD::Registry.root
  content += "nav_order: #{object_nav_order(object)}\n"
  content += "has_children: true\n" if has_children?(object)
  content += "---\n\n"
  
  # Add heading and docstring
  content += "# #{object.name}\n\n"
  
  if object.type == :class
    content += "**Class in namespace:** `#{object.namespace}`\n\n"
    content += "**Inherits:** `#{object.superclass}`\n\n" if object.superclass && object.superclass != 'Object'
  else
    content += "**Module in namespace:** `#{object.namespace}`\n\n"
  end
  
  if object.docstring && !object.docstring.empty?
    content += "#{object.docstring}\n\n"
  end
  
  # Add class/module methods section
  unless class_methods.empty?
    content += "## Class Methods\n\n"
    
    class_methods.sort_by(&:name).each do |method|
      content += method_documentation(method)
    end
  end
  
  # Add instance methods section
  unless instance_methods.empty?
    content += "## Instance Methods\n\n"
    
    instance_methods.sort_by(&:name).each do |method|
      content += method_documentation(method)
    end
  end
  
  # Write to file
  File.write(output_path, content)
  puts "Generated documentation for #{object.path} at #{output_path}"
end

def method_documentation(method)
  content = "### `#{method.name}`\n\n"
  
  # Method signature
  signature = method.signature.gsub('def ', '')
  content += "<div class=\"method-signature\">#{signature}</div>\n\n"
  
  # Method description
  if method.docstring && !method.docstring.empty?
    content += "#{method.docstring}\n\n"
  end
  
  # Parameters
  unless method.parameters.empty?
    content += "**Parameters:**\n\n"
    content += "<div class=\"method-parameters\">\n"
    
    method.parameters.each do |name, default|
      param_tag = method.tags(:param).find { |tag| tag.name == name.to_s }
      content += "* <span class=\"parameter-name\">#{name}</span>"
      content += " = #{default}" if default
      content += " — #{param_tag.text}" if param_tag && param_tag.text
      content += "\n"
    end
    
    content += "</div>\n\n"
  end
  
  # Return value
  if method.has_tag?(:return) && method.tag(:return).text
    content += "**Returns:**\n\n"
    content += "#{method.tag(:return).text}\n\n"
  end
  
  # Examples
  if method.has_tag?(:example)
    content += "**Examples:**\n\n"
    
    method.tags(:example).each do |example|
      content += "```ruby\n#{example.text}\n```\n\n"
    end
  end
  
  content += "---\n\n"
  content
end

def has_children?(object)
  YARD::Registry.all.any? { |o| o.namespace == object }
end

def object_nav_order(object)
  # Order namespaces first, then classes, then modules
  order = case object
  when YARD::CodeObjects::NamespaceObject
    1
  when YARD::CodeObjects::ClassObject
    2
  when YARD::CodeObjects::ModuleObject
    3
  else
    4
  end
  
  # Add alphabetical ordering within each type
  "#{order}#{object.name.to_s.downcase}"
end

# Entry point
generate_pages if __FILE__ == $PROGRAM_NAME
