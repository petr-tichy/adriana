class ChangeJobEntityReferences < ActiveRecord::Migration
  def change
    rename_column :job_entity, :project, :r_project
    rename_column :job_entity, :schedule, :r_schedule
    rename_column :job_entity, :customer, :r_customer
  end
end
