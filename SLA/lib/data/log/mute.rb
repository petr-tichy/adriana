module SLAWatcher
  class Mute < ActiveRecord::Base
    self.table_name = 'mute'
    self.primary_key = 'id'

    belongs_to :contract
    belongs_to :project, :foreign_key => 'project_pid'
    belongs_to :schedule

    def active?
      current_date = DateTime.now
      current_date >= self.start && current_date <= self.end && !disabled?
    end

    def disabled?
      self.disabled
    end
  end
end