# Author: Stephen Sykes
# http://pennysmalls.com

module SlimDbTestUtils
  DB_NAME = "slim_attributes_test"

  def self.db_config
    @config ||= YAML.load(File.read(File.dirname(__FILE__) + "/database.yml"))
    @config[DB_NAME]
  end

  def self.connect_and_create_db
    connect_with_config(db_config)
    unless ActiveRecord::Base.connected?  # database did not exist (as expected)
      connect_with_config(db_config.merge({"database"=>nil}))
      ActiveRecord::Base.connection.create_database(db_config["database"])
      connect_with_config(db_config)
    end
  end
  
  def self.connect_with_config(config)
    begin
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection
    rescue Mysql::Error
    end
  end
  
  def self.remove_db
    if ActiveRecord::Base.connected?
      ActiveRecord::Base.connection.execute("DROP DATABASE #{db_config["database"]}")
    end
  end
  
  def self.import_sql(file)
    `mysql -p#{db_config["password"]} -u #{db_config["username"]} #{db_config["database"]} < #{File.dirname(__FILE__)}/#{file}`
  end
end
