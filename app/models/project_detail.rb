class ProjectDetail < ActiveRecord::Base
  self.table_name = 'project_detail'
  set_primary_key "project_pid"

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :salesforce_type, :practice_group,:note,:solution_architect,:solution_engineer,:confluence,:automatic_validation,:tier,:working_hours,:time_zone,:restart,:tech_user,:uses_ftp,:uses_es,:archiver,:sf_downloader_version,:directory_name,:salesforce_id,:salesforce_name
  # attr_accessible :title, :body
end
