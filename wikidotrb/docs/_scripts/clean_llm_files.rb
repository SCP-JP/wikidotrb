#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

# This script cleans up the llms-full.txt file by replacing remaining
# Japanese comments with English translations

module LlmsCleaner
  TRANSLATIONS = {
    # Client methods
    "デストラクタ" => "Destructor",
    "基幹クライアント" => "Core client",
    "ログインチェック" => "Login check",
    
    # Forum methods
    "カテゴリのプロパティ" => "Category property",
    "フォーラムのURLを取得" => "Get forum URL",
    "グループのプロパティ" => "Group property",
    "初期化メソッド" => "Initialization method",
    
    # Other common terms
    "初期化" => "Initialize",
    "取得" => "Get",
    "設定" => "Set",
    "メソッド" => "Method",
    "プロパティ" => "Property"
  }

  class << self
    def clean
      # Generate in YARD output directory
      site_dir = "docs/api/yard"
      
      # Clean llms.txt and llms-full.txt
      clean_files(site_dir)
      
      puts "Cleaned Japanese comments from LLM files"
    end

    private

    def clean_files(site_dir)
      # Clean llms-full.txt
      llms_full_path = File.join(site_dir, "llms-full.txt")
      
      if File.exist?(llms_full_path)
        content = File.read(llms_full_path, encoding: 'UTF-8')
        
        # Replace Japanese comments
        TRANSLATIONS.each do |japanese, english|
          content = content.gsub(japanese, english)
        end
        
        # Write back
        puts "Writing cleaned llms-full.txt"
        File.write(llms_full_path, content)
      else
        puts "Warning: #{llms_full_path} not found"
      end
    end
  end
end

LlmsCleaner.clean
