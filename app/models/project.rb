class Project < ActiveRecord::Base
  self.table_name = 'project'
  self.primary_key = 'project_pid'

  belongs_to :contract
  validates_presence_of :status,:name,:project_pid,:contract_id

  #set_primary_key "project_pid"

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable

  def self.get_public_attributes
    ["status","name","ms_person","contract_id"]
  end

  # Setup accessible (or protected) attributes for your model
  attr_accessible :status, :name, :ms_person,:customer_name,:customer_contact_name,:customer_contact_email,:project_pid,:contract_id
  # attr_accessible :title, :body

  # Added chaining of deletion to schedules
  def self.mark_deleted(id,user)
    project = Project.find(id)
    ProjectHistory.add_change(project.project_pid,"is_deleted","true",user)
    project.is_deleted = true
    project.updated_by = user.id
    project.save

    schedules =  Schedule.where("r_project = ?",project.project_pid)
    schedules.each do |schedule|
      Schedule.mark_deleted(schedule.id,user)
    end
  end

  def self.find_by_id(id)
    Project.find(id)
  end


end
