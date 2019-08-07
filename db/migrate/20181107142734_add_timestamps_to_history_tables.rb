class AddTimestampsToHistoryTables < ActiveRecord::Migration[5.0]
  TABLES = %i(contract_history customer_history project_history schedule_history).freeze

  def self.up
    TABLES.each do |t|
      add_column t, :created_at, :datetime, null: true
      add_column t, :updated_at, :datetime, null: true

      # Backfill existing records with created_at and updated_at
      # values making clear that the records are faked
      long_ago = DateTime.new(2000, 1, 1)
      t.to_s.camelize.constantize.update_all(created_at: long_ago, updated_at: long_ago)

      # change not null constraints
      change_column_null t, :created_at, false
      change_column_null t, :updated_at, false
    end
  end

  def self.down
    TABLES.each do |t|
      remove_column t, :created_at
      remove_column t, :updated_at
    end
  end
end
