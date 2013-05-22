
module SLAWatcher
  class ScheduleHistory < ActiveRecord::Base
    self.table_name = 'log2.schedule_history'
  end
end