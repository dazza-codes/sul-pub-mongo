#!/usr/bin/env ruby

require 'bundler/setup'
require 'pry'

require 'json'
require 'yaml'
require 'hashie'

require_relative 'sulpub_sql'
@sulpub_sql = SulPub::SqlDb.new

def logger
  @logger ||= begin
    require 'logger'
    begin
      log_file = 'log/sulpub_sql_inspector.log'
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

format = "Publication:  %8d"
progress = sprintf format, 0
backup = "\b"*progress.length
# @sulpub_sql.publications.limit(200).each_with_index do |pub, i|

pubs = @sulpub_sql.publications
pubs = pubs.where('LOWER(pub_hash) LIKE "%provenance: cap%"')
printf "Publications: %8d\n", pubs.count
pubs.each_with_index do |pub, i|
  $stderr.write backup if i > 0
  progress = sprintf format, i+1
  $stderr.write progress

  begin
    pub_yaml = pub.delete :pub_hash
    pub_hash = YAML::load(pub_yaml)

    if pub_hash[:provenance].downcase != 'cap'
      # Something is wrong with the SQL filter
      binding.pry
    end

    if pub_hash[:authorship].length > 1
      authorship_ids = pub_hash[:authorship].map {|a| a[:cap_profile_id]}
      authorship_set = authorship_ids.to_set
      if authorship_set.length != authorship_ids.length
        binding.pry
        # pub[:updated_at]
      end
      authorship_ids = pub_hash[:authorship].map {|a| a[:sul_author_id]}
      authorship_set = authorship_ids.to_set
      if authorship_set.length != authorship_ids.length
        binding.pry
        # pub[:updated_at]
      end
    end

  rescue => e
    log_exception e, pub, pub_yaml
    binding.pry
  end
end

logger.info "Finished at: #{Time.now}"
$stderr.write "\n"
