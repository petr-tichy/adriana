class ExecutionLog < ActiveRecord::Base
  self.table_name = 'execution_log'


  def self.get_last_executions
    select("*").joins("INNER JOIN schedule s ON s.id = r_schedule").where("NOT EXISTS (SELECT * FROM execution_log e WHERE e.r_schedule = r_schedule AND e.id > id) AND s.main = 't'")
  end

  def self.get_last_x_executions(number_of_execution,schedule)
    select("*").where("r_schedule = ?",schedule).order("event_start DESC").limit(number_of_execution)
  end




end
