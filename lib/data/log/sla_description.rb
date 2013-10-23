module SLAWatcher
  class SLADescription < ActiveRecord::Base
    self.table_name = 'log2.sla_description'


    def self.get_data_for_sheet
      select("sla_description.id as id, sla_description.sla_description_type as description_type, sla_description.sla_description_text as description_text,sla_description.sla_type as sla_type,sla_description.sla_value as sla_value,p.project_pid as project_pid,p.name as project_name,l.event_start::date as event_start").joins("INNER JOIN log2.execution_log l ON sla_description.id = l.id").joins("INNER JOIN log2.schedule s ON l.r_schedule = s.id").joins("INNER JOIN log2.project p ON p.project_pid = s.r_project").where("p.contract_id IS NULL").order("l.event_start DESC")
    end

  end
end