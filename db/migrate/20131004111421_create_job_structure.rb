class CreateJobStructure < ActiveRecord::Migration
  def change
    create_table "job_type",{:id => false} do |t|
      t.integer "id",:null => false
      t.string "name", :limit => 50, :null => false
      t.timestamps
    end

    create_table "job" do |t|
      t.references :job_type, index: false
      t.datetime "scheduled_at"
      t.datetime "started_at"
      t.datetime "finished_at"
      t.string "status",:limit => 50, :null => false
      t.text "log"
      t.string "scheduled_by"
      t.boolean "recurrent"
      t.timestamps
    end


    create_table "job_entity" do |t|
      t.references :job, index: true
      t.string :project, :null => true
      t.integer :schedule, :null => true
      t.integer :customer, :null => true
      t.string "status",:limit => 50, :null => false
      t.timestamps
    end

    create_table "job_parameter" do |t|
      t.references :job, index: true
      t.string :key, :null => false
      t.text :value, :null => false
    end

    execute "INSERT INTO job_type (id,name,updated_at,created_at) VALUES (1,'Restart',now(),now());"
    execute "INSERT INTO job_type (id,name,updated_at,created_at) VALUES (2,'Synchronize PWB customer',now(),now());"
    execute "INSERT INTO job_type (id,name,updated_at,created_at) VALUES (3,'Update schedules',now(),now());"
    execute "INSERT INTO job_type (id,name,updated_at,created_at) VALUES (4,'Update notifications',now(),now());"

  end


end
