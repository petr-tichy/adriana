class ProjectDetail < ActiveRecord::Base
  self.table_name = 'project_detail'
  self.primary_key = 'project_pid'
  #set_primary_key "project_pid"

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
end
