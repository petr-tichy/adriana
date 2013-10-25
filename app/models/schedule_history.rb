class ScheduleHistory < ActiveRecord::Base
  self.table_name = 'schedule_history'
  attr_accessible :schedule_id,:key,:value,:valid_from,:valid_to,:updated_by

  def self.add_change(schedule_id,key,value,user)
    date = DateTime.now
    last_record = ScheduleHistory.where("schedule_id = ? and key = ? and ((valid_from IS NOT NULL AND valid_to IS NULL) OR (valid_from IS NULL and valid_to IS NULL))",schedule_id,key).first
    if (!last_record.nil?)
      last_record.valid_to = date
      last_record.save
      ScheduleHistory.create(:schedule_id => schedule_id,:key => key,:value => value,:valid_from => date,:valid_to => nil, :updated_by => user.id )
    else
      ScheduleHistory.create(:schedule_id => schedule_id,:key => key,:value => value,:valid_from => nil,:valid_to => nil, :updated_by => user.id )
    end

  end

end