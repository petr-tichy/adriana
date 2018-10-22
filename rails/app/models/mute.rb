class Mute < ActiveRecord::Base
  self.table_name = 'mute'
  self.primary_key = 'id'

  just_define_datetime_picker :start
  just_define_datetime_picker :end

  validates_presence_of :start, :end, :reason, :admin_user_id
  validate :reference_validation, :date_validation

  belongs_to :admin_user
  belongs_to :contract, :foreign_key => 'contract_id', :primary_key => 'id'
  belongs_to :project, :foreign_key => 'project_pid', :primary_key => 'project_pid'
  belongs_to :schedule, :foreign_key => 'schedule_id', :primary_key => 'id'

  def active?
    current_date = DateTime.now
    current_date >= self.start && current_date <= self.end && !disabled?
  end

  def disabled?
    self.disabled
  end

  private

  def reference_validation
    unless [contract_id, project_pid, schedule_id].map { |x| x.present? ? 1 : 0 }.sum == 1
      errors.add(:base, 'Exactly one of contract_id, project_pid, schedule_id must be specified.')
    end
  end

  def date_validation
    if self.end && self.start && self.end <= self.start
      errors.add(:base, 'End date must be after start date.')
    end
  end
end
