# Author: Stephen Sykes
# http://pennysmalls.com

module SlimDbTestUtils
  DB_NAME = "slim_attributes_test"

  def self.connect_and_create_db
    config = YAML.load(File.read(File.dirname(__FILE__) + "/database.yml"))
    connect_with_config(config[DB_NAME])
    unless ActiveRecord::Base.connected?  # database did not exist (as expected)
      connect_with_config(config[DB_NAME].merge({"database"=>nil}))
      ActiveRecord::Base.connection.create_database(DB_NAME)
      connect_with_config(config[DB_NAME])
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
      ActiveRecord::Base.connection.execute("DROP DATABASE #{DB_NAME}")
    end
  end
end
