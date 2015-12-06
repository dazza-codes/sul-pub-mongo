require 'mongo'

module SulPub
  class MongoRepo

    def initialize
      sulpub_mongo_logger
      sulpub_repo_mongo
    end

    #######################################
    # Collections

    def publications
      @publications ||= sulpub_repo_mongo[:publications]
    end


    #######################################
    # Core collection queries

    # return publication data for one profile from local repo
    # @param id [Integer] A profileId number
    # @return publications [Hash|nil]
    def publication_doc(id)
      publications.find({_id: id}).first
    end

    # return all publication data from local repo
    # @return publications [Array<Hash>]
    def publication_docs
      publications.find.to_a
    end


    #######################################
    # Admin Utilities

    def repo_clean
      publications.drop
      publications.create
      puts "Cleared saved publications."
    end

    def repo_commit
      publication_indexes
      puts "Stored #{publications.find.count} publications."
      puts "Stored publications to #{publications.class} at: #{publications.namespace}."
    end

    def publication_indexes
      publications.indexes.create_one({'author.lastName'  => 1})
      publications.indexes.create_one({'author.firstName' => 1})
      publications.indexes.create_one({'pmid'  => 1})
      publications.indexes.create_one({'issn'  => 1})
      publications.indexes.create_one({'type'  => 1})
    end



    #######################################
    # Init Utilities

    private

    # Create a repository for storing SULSULPUB json data
    def sulpub_repo_mongo
      @sulpub_repo_mongo ||= begin
        sulpub_mongo_logger
        if ENV['SULPUB_REPO_MONGO']
          repo = ENV['SULPUB_REPO_MONGO'].dup
        else
          repo = 'mongodb://127.0.0.1:27017/sulpub'
        end
        Mongo::Client.new(repo)
      end
    end

    def sulpub_mongo_logger
      @sulpub_mongo_logger ||= begin
        require 'logger'
        begin
          log_file = ENV['SULPUB_LOG_FILE'] || 'log/sulpub_repo_mongo.log'
          @log_file = File.absolute_path log_file
          FileUtils.mkdir_p File.dirname(@log_file) rescue nil
          log_dev = File.new(@log_file, 'w+')
        rescue
          log_dev = $stderr
          @log_file = 'STDERR'
        end
        log_dev.sync = true if @debug # skip IO buffering in debug mode
        logger = Logger.new(log_dev, 'weekly')
        logger.level = @debug ? Logger::DEBUG : Logger::INFO
        Mongo::Logger.logger = logger
        logger
      end
    end

  end
end
