module SLAWatcher
  class Settings < ActiveRecord::Base
    self.table_name = 'settings'

    def self.load_last_splunk_synchronization
      where("key = 'last_splunk_synchronization'")
    end

    def self.load_project_category_id
      select("value").where("key = 'project_maintanence_category'")
    end


    def self.load_schedule_category_id
      select("value").where("key = 'task_maintanence_category'")
    end


    def self.save_last_splunk_synchronization(time)
      record = where("key = 'last_splunk_synchronization'")
      record.first.value = Helper.datetime_to_value(time)
      record.first.save
    end

  end
end