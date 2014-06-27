class ProjectDetail < ActiveRecord::Base
  self.table_name = 'project_detail'
  self.primary_key = 'project_pid'
  #set_primary_key "project_pid"
  belongs_to :project, :primary_key => "project_pid", :foreign_key => "project_pid"

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable

  # Setup accessible (or protected) attributes for your model

  # attr_accessible :title, :body
end
