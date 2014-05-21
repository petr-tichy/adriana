module SLAWatcher
  class Request < ActiveRecord::Base
    self.table_name = 'log3.temp_request'


    def self.check_request_id_started
      select("temp_request.request_id as request_id").joins("LEFT OUTER JOIN log3.execution_log l ON l.request_id  = temp_request.request_id").where("l.request_id IS NULL")
    end

    def self.check_request_id_finished
      select("temp_request.request_id as request_id").joins("LEFT OUTER JOIN log3.execution_log l ON l.request_id  = temp_request.request_id AND l.status != 'RUNNING'").where("l.request_id IS NULL")
    end
  end
end