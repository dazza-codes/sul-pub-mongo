# sul-pub-mongo
A utility to map Stanford sul-pub SQL records into MongoDb.  This is intended only for development laptops, it was created very quickly to provide very basic ETL functionality for sul_pub publications (the pub_hash data cannot be easily searched in MySQL, but it can be after an ETL to MongoDb).

# Prerequisites

It's assumed that you already have a sul_pub project and a recent production db dump to work with.  This utility is designed to faciliate extracting the Publication.pub_hash data into MongoDb for easy indexing and searching of this large blob.

[Install mongodb](https://docs.mongodb.com/manual/installation/).  A default installation should be fine and there is no additional setup required.  Try [robomongo](https://robomongo.org/) - it's a nice UI.

# Setup

Clone and configure the project

    git clone git@github.com:sul-dlss/sul-pub-mongo.git
    cd sul-pub-mongo
    bundle install
    
Setup the sul_pub database details.  The `sulpub_sql.rb` will use the `database.yml` values for `RAILS_ENV` or default to the `development` configuration.

    # copy the example database.yml or copy your existing
    # one from a clone of the sul_pub/config/database.yml
    # it's assumed the db is MySQL
    cp config/database.yml.example config/database.yml
    # check and update it for your database
    vim config/database.yml

Check the mongodb configuration, if necessary.  The defaults in `sulpub_mongo.rb` should be OK.

Try the console, e.g.

    bundle exec ./sulpub_console.rb
    > @sulpub_sql.publications.count

# Conversion

Run the ETL:

    bundle exec ./sulpub_sql2mongo.rb

Wait a while for a large production data ETL.  When done, look at the 'sulpub' db and the 'publications' collection in MongoDb.  Some useful query language help can be reviewed at https://docs.mongodb.com/manual/tutorial/query-documents/.  The MongoDb query language is javascript.

# Scripting the pub_hash

Take a look at `sulpub_sql_inspector.rb` as an example of scripting something for the Publication.pub_hash data without using MongoDb.
