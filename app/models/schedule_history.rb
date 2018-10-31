class ScheduleHistory < ActiveRecord::Base
  self.table_name = 'schedule_history'

  def self.add_change(schedule_id,key,value,user)
    date = DateTime.now
    last_record = ScheduleHistory.where("schedule_id = ? and key = ? and ((valid_from IS NOT NULL AND valid_to IS NULL) OR (valid_from IS NULL and valid_to IS NULL))",schedule_id,key).first
    if (!last_record.nil?)
      last_record.valid_to = date
      last_record.save
      ScheduleHistory.create(:schedule_id => schedule_id,:key => key,:value => value,:valid_from => date,:valid_to => nil, :updated_by => user.id)
    else
      ScheduleHistory.create(:schedule_id => schedule_id,:key => key,:value => value,:valid_from => nil, :valid_to => nil, :updated_by => user.id)
    end

  end

  def self.mass_add_change(schedules,key,value,user)
    date = DateTime.now
    schedule_ids = schedules.map{|s| s.id}
    last_records = ScheduleHistory.where("schedule_id IN (?) and key = ? and ((valid_from IS NOT NULL AND valid_to IS NULL) OR (valid_from IS NULL and valid_to IS NULL))",schedule_ids,key)
    list_of_schedules = last_records.map {|l| l.schedule_id }

    schedules_without_record = schedule_ids - list_of_schedules

    inserts = []
    list_of_schedules.each do |s|
      inserts.push "(#{s},'#{key}','#{value}','#{date.utc}', #{user.id})"
    end

    schedules_without_record.each do |s|
      inserts.push "(#{s},'#{key}','#{value}',NULL, #{user.id})"
    end

    sql = "INSERT INTO schedule_history (schedule_id, key, value, valid_from, updated_by) VALUES #{inserts.join(", ")}"
    last_records.update_all(valid_to: date)
    ActiveRecord::Base.connection.execute sql
  end
end