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
@sulpub_mongo.repo_clean

def logger
  @logger ||= begin
    require 'logger'
    begin
      log_file = 'log/sulpub_sql2mongo.log'
      @log_file = File.absolute_path log_file
      FileUtils.mkdir_p File.dirname(@log_file) rescue nil
      log_dev = File.new(@log_file, 'w+')
    rescue
      log_dev = $stderr
      @log_file = 'STDERR'
    end
    log_dev.sync = true
    logger = Logger.new(log_dev, 'weekly')
    logger.level = Logger::DEBUG
    logger
  end
end
logger.info "Starting at: #{Time.now}"

def log_exception(e, pub, pub_yaml)
  msg = e.message
  msg += "\n"
  msg += e.backtrace.join("\n")
  msg += "\n"
  msg += JSON.dump(pub)
  msg += "\n"
  msg += pub_yaml
  msg += "\n"
  logger.error msg
end

# @sulpub_sql.publications.limit(5).each do |pub|
@sulpub_sql.publications.each do |pub|
  begin
    pub_yaml = pub.delete :pub_hash
    pub_hash = YAML::load(pub_yaml)

    # Remove duplicate identifiers
    if pub_hash[:identifier]
      pub_hash[:identifier] = pub_hash[:identifier].to_set.to_a
    end

    # PubMed ID
    if pub_hash[:pmid].nil? && pub[:pmid]
      pub_hash[:pmid] = pub[:pmid]
    end
    if pub_hash[:pmid].instance_of? String
      pub_hash[:pmid] = pub_hash[:pmid].to_i
    end

    # ScienceWire ID
    if pub_hash[:sciencewire_id].nil? && pub[:sciencewire_id]
      pub_hash[:sciencewire_id] = pub[:sciencewire_id]
    end
    if pub_hash[:sciencewire_id].instance_of? String
      pub_hash[:sciencewire_id] = pub_hash[:sciencewire_id].to_i
    end

    # get the dates
    pub_hash[:created_at] = pub[:created_at]
    pub_hash[:updated_at] = pub[:updated_at]

    # get the publication status
    pub_hash[:active] = pub[:active]
    pub_hash[:deleted] = pub[:deleted] || false

    # check authorship for duplicates
    if pub_hash[:authorship].instance_of? Array
      authorship_set = pub_hash[:authorship].to_set.to_a
      if authorship_set.length != pub_hash[:authorship].length
        logger.error "Found duplicate authorship in: #{pub[:id]}"
      end
      pub_hash[:authorship] = authorship_set.to_a
    end

    # Save to mongo
    pub_hash[:sulpubid] = pub[:id]
    pub_hash['_id'] = pub[:id]
    @sulpub_mongo.publications.insert_one(pub_hash)
  rescue => e
    log_exception e, pub, pub_yaml
    # binding.pry
  end
end

@sulpub_mongo.repo_commit
logger.info "Finished at: #{Time.now}"
