
module SLAWatcher
# connect to the database
  class Connection

    def self.connect(hostname,port,username,password,database)
      ActiveRecord::Base.logger = Logger.new(STDOUT)
      ActiveRecord::Base.establish_connection(:adapter => 'postgresql',
                                              :host => hostname,
                                              :port => port,
                                              :username => username,
                                              :password => password,
                                              :database => database)
    end



  end
end