#!/usr/bin/env ruby

require 'bundler/setup'
require 'pry'

require 'json'
require 'yaml'
require 'hashie'

require_relative 'sulpub_sql'
@sulpub_sql = SulPub::SqlDb.new

require_relative 'sulpub_mongo'
@sulpub_mongo = SulPub::MongoRepo.new

binding.pry

# @sulpub_sql.publications.filter('updated_at > ?', Date.today - 7)
