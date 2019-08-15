class ProjectDetail < ActiveRecord::Base
  self.table_name = 'project_detail'
  self.primary_key = 'project_pid'

  belongs_to :project, :primary_key => 'project_pid', :foreign_key => 'project_pid'
end
