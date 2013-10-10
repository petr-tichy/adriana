class JobEntity < ActiveRecord::Base
  self.table_name = 'job_entity'
  has_one :job
  attr_accessible :job_id, :status, :r_schedule,:r_project,:r_company


  def self.get_job_entities_schedule(job_id)
    select("p.name as project_name,s.graph_name,s.mode,job_entity.status").joins("INNER JOIN schedule s ON s.id = job_entity.r_schedule").joins("INNER JOIN project p ON p.project_pid = s.r_project").where("job_entity.job_id = ?",job_id)
  end


end