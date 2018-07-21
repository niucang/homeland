# frozen_string_literal: true

require "elasticsearch/rails/instrumentation"
require 'typhoeus'
require 'typhoeus/adapters/faraday'
config = Rails.application.config_for(:elasticsearch)

Elasticsearch::Model.client = Elasticsearch::Client.new host: config["host"]
