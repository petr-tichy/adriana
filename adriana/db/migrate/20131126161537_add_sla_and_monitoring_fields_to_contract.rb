class AddSlaAndMonitoringFieldsToContract < ActiveRecord::Migration
  def change

    add_column :contract,:sla_enabled,:boolean,:default => false
    add_column :contract,:sla_type,:string
    add_column :contract,:sla_value,:string
    add_column :contract,:sla_percentage,:integer
    add_column :contract,:monitoring_enabled,:boolean,:default => false
    add_column :contract,:monitoring_emails,:string

  end
end
