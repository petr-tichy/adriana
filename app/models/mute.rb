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

  scope :active, -> { where(:disabled => false).where('mute."start" <= ?', DateTime.now).where('mute."end" >= ?', DateTime.now) }
  scope :inactive, -> { where.not(:id => active.map(&:id)) }

  def now_in_range?
    current_date = DateTime.now
    current_date >= self.start && current_date <= self.end
  end

  def active?
    now_in_range? && !disabled?
  end

  def muted_object
    contract || project || schedule
  end

  def muted_object_type
    muted_object.class.to_s.humanize
  end

  alias_method :reference_type, :muted_object_type

  def reference_id
    muted_object.send(muted_object.class.primary_key.to_sym)
  end

  scope :active_eq, ->(flag) { flag.to_sym == :active ? active : inactive }

  def self.ransackable_scopes(auth_object = nil)
    [:active_eq]
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
      return false
    end
    true
  end
end
