class ProjectHistory < ActiveRecord::Base
  self.table_name = 'project_history'
  attr_accessible :project_pid,:key,:value,:valid_from,:valid_to,:updated_by

  def self.add_change(project_pid,key,value,user)
    date = DateTime.now
    last_record = ProjectHistory.where("project_pid = ? and key = ? and ((valid_from IS NOT NULL AND valid_to IS NULL) OR (valid_from IS NULL and valid_to IS NULL))",project_pid,key).first
    if (!last_record.nil?)
      last_record.valid_to = date
      last_record.save!
      ProjectHistory.create(:project_pid => project_pid,:key => key,:value => value,:valid_from => date,:valid_to => nil, :updated_by => user.id )
    else
      ProjectHistory.create(:project_pid => project_pid,:key => key,:value => value,:valid_from => nil,:valid_to => nil, :updated_by => user.id )
    end

  end

end