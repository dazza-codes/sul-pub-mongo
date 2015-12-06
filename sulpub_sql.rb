require 'logger'
require 'mysql2'
require 'sequel'
# An interface to the sulpub SQL database using Sequel
# @see http://sequel.jeremyevans.net/documentation.html Sequel RDoc
# @see http://sequel.jeremyevans.net/rdoc/files/README_rdoc.html Sequel Readme
# @see http://sequel.jeremyevans.net/rdoc/files/doc/code_order_rdoc.html Sequel code order

module SulPub
  class SqlDb

    attr_accessor :db
    attr_accessor :db_config

    def log_model_info(m)
      sulpub_sql_logger.info "table: #{m.table_name}, columns: #{m.columns}, pk: #{m.primary_key}"
    end

    def initialize
      @db_config = {}
      @db_config['host']     = ENV['SULPUB_DB_HOST'] || 'localhost'
      @db_config['port']     = ENV['SULPUB_DB_PORT'] || '3306'
      @db_config['user']     = ENV['SULPUB_DB_USER'] || 'capAdmin'
      @db_config['password'] = ENV['SULPUB_DB_PASS'] || 'capPass'
      @db_config['database'] = ENV['SULPUB_DB_DATABASE'] || 'cap'
      options = @db_config.merge({
        :encoding => 'utf8',
        :max_connections => 10,
        :logger => sulpub_sql_logger
      })
      @db = Sequel.mysql2(options)
      @db.extension(:pagination)
      # Ensure the connection is good on startup, raises exceptions on failure
      sulpub_sql_logger.info "#{@db} connected: #{@db.test_connection}"
    end

    def publication(id)
      @db[:publications][:id => id]
    end

    def publications
      @db[:publications]
    end

    # def publication_ids
    #   @db[:publications].order(:user_id).select(:user_id, :id)
    # end

    # def publications_join_users
    #   @db[:publications].join_table(:inner, @db[:users], :id=>:user_id)
    #   # @db[:publications].join_table(:outer, @db[:users], :id=>:user_id)
    # end

    # def users
    #   @db[:users]
    # end

    # def user(id)
    #   @db[:users][:id => id]
    # end

    private

    def sulpub_sql_logger
      @sulpub_sql_logger ||= begin
        begin
          log_file = ENV['SULPUB_LOG_FILE'] || 'log/sulpub_repo_sql.log'
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
        logger
      end
    end

  end

end

