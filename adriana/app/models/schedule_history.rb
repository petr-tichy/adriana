class ScheduleHistory < ActiveRecord::Base
  self.table_name = 'schedule_history'
  belongs_to :schedule

  def self.add_change(schedule_id, key, value, user, is_indirect: false)
    date = DateTime.now
    last_record = ScheduleHistory.where("schedule_id = ? and key = ? and ((valid_from IS NOT NULL AND valid_to IS NULL) OR (valid_from IS NULL and valid_to IS NULL))", schedule_id, key).first
    if last_record
      last_record.valid_to = date
      last_record.updated_by = user.id
      last_record.save
      ScheduleHistory.create(:schedule_id => schedule_id, :key => key, :value => value, :valid_from => date, :valid_to => nil, :updated_by => user.id, :is_indirect => is_indirect)
    else
      ScheduleHistory.create(:schedule_id => schedule_id, :key => key, :value => value, :valid_from => nil, :valid_to => nil, :updated_by => user.id, :is_indirect => is_indirect)
    end

  end

  def self.mass_add_change(schedules, key, value, user, is_indirect: false)
    date = DateTime.now
    schedule_ids = schedules.map(&:id)
    last_records = ScheduleHistory.where("schedule_id IN (?) and key = ? and ((valid_from IS NOT NULL AND valid_to IS NULL) OR (valid_from IS NULL and valid_to IS NULL))", schedule_ids, key)
    list_of_schedules = last_records.map(&:schedule_id)

    schedules_without_record = schedule_ids - list_of_schedules

    ActiveRecord::Base.transaction do
      list_of_schedules.each do |s|
        ScheduleHistory.create(:schedule_id => s, :key => key, :value => value, :valid_from => date, :valid_to => nil, :updated_by => user.id, :is_indirect => is_indirect)
      end
      schedules_without_record.each do |s|
        ScheduleHistory.create(:schedule_id => s, :key => key, :value => value, :valid_from => date, :valid_to => nil, :updated_by => user.id, :is_indirect => is_indirect)
      end
      last_records.update_all(valid_to: date)
    end
  end

  def related_record
    schedule
  end
end