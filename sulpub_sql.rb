require 'yaml'
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

    def initialize
      options = db_config.merge({
        :max_connections => db_config['pool'],
        :logger => sulpub_sql_logger
      })
      # TODO: enable adapter options.
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

    def db_config
      @db_config ||= begin
        db_yml = File.expand_path(File.join('.', 'config', 'database.yml'))
        db_conf = YAML.load(File.open(db_yml).read) || {}
        rails_env = ENV['RAILS_ENV'] || 'development'
        conf = db_conf[rails_env] || {}
        conf['host']     ||= 'localhost'
        conf['port']     ||= '3306'
        conf['user']     ||= 'capAdmin'
        conf['password'] ||= 'capPass'
        conf['database'] ||= 'sulbib_development'
        conf['encoding'] ||= 'utf8'
        conf['pool']     ||= 5
        conf
      end
    end

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

    def log_model_info(m)
      sulpub_sql_logger.info "table: #{m.table_name}, columns: #{m.columns}, pk: #{m.primary_key}"
    end

  end

end

