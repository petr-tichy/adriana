class ExecutionLog < ActiveRecord::Base
  self.table_name = 'execution_log'


  def self.get_last_executions
    select("*").joins("INNER JOIN schedule s ON s.id = r_schedule").where("NOT EXISTS (SELECT * FROM execution_log e WHERE e.r_schedule = r_schedule AND e.id > id) AND s.main = 't'")
  end




end
