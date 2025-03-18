# frozen_string_literal: true

require "logger"

module Wikidotrb
  module Common
    # Logger Configuration
    def self.setup_logger(name = "wikidot", level = Logger::INFO)
      # Create logger
      _logger = Logger.new($stdout)
      _logger.progname = name
      _logger.level = level

      # Log format
      _logger.formatter = proc do |severity, datetime, progname, msg|
        "#{datetime} [#{progname}/#{severity}] #{msg}\n"
      end

      _logger
    end

    # Initialize logger
    Logger = setup_logger
  end
end
