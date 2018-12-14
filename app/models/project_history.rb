class ProjectHistory < ActiveRecord::Base
  self.table_name = 'project_history'
  belongs_to :project, foreign_key: 'project_pid'

  def self.add_change(project_pid, key, value, user, is_indirect: false)
    date = DateTime.now
    last_record = ProjectHistory.where("project_pid = ? and key = ? and ((valid_from IS NOT NULL AND valid_to IS NULL) OR (valid_from IS NULL and valid_to IS NULL))", project_pid, key).first
    if !last_record.nil?
      last_record.valid_to = date
      last_record.updated_by = user.id
      last_record.save!
      ProjectHistory.create(:project_pid => project_pid, :key => key, :value => value, :valid_from => date, :valid_to => nil, :updated_by => user.id, :is_indirect => is_indirect)
    else
      ProjectHistory.create(:project_pid => project_pid, :key => key, :value => value, :valid_from => nil, :valid_to => nil, :updated_by => user.id, :is_indirect => is_indirect)
    end
  end

  def related_record
    project
  end
end