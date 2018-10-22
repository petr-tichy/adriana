
module SLAWatcher
# connect to the database
  class Connection

    def self.connect(hostname,port,username,password,database)
      ActiveRecord::Base.logger = @@log
      config = YAML::load(File.open('config/database.yml'))
      ActiveRecord::Base.establish_connection(config["database"])
    end



  end
end