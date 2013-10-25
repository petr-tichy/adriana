# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20131024132546) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "admin_users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "contract", :force => true do |t|
    t.string   "name",        :limit => 50, :default => "Empty customer", :null => false
    t.datetime "created_at",                                              :null => false
    t.datetime "updated_at",                                              :null => false
    t.boolean  "is_deleted",                :default => false
    t.integer  "customer_id"
  end

  create_table "contract_history", :force => true do |t|
    t.integer  "contract_id"
    t.string   "value",       :limit => 250
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.text     "updated_by"
    t.text     "key"
  end

  create_table "customer", :force => true do |t|
    t.string   "name",           :limit => 50, :default => "Empty customer", :null => false
    t.string   "email"
    t.string   "contact_person"
    t.datetime "created_at",                                                 :null => false
    t.datetime "updated_at",                                                 :null => false
    t.boolean  "is_deleted",                   :default => false
  end

  create_table "customer_history", :force => true do |t|
    t.integer  "customer_id"
    t.string   "value",       :limit => 250
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.text     "updated_by"
    t.text     "key"
  end

  create_table "dump_log", :force => true do |t|
    t.string   "project_pid", :limit => 100
    t.string   "graph_name"
    t.string   "mode"
    t.text     "text"
    t.string   "updated_by",  :limit => 100
    t.datetime "updated_at"
  end

  add_index "dump_log", ["id"], :name => "IX__dump_log_id"

  create_table "event_log", :id => false, :force => true do |t|
    t.string   "project_pid",  :limit => 100
    t.string   "graph_name",   :limit => 100
    t.string   "mode"
    t.integer  "severity"
    t.string   "event_type"
    t.text     "text"
    t.datetime "created_date"
    t.boolean  "persistent"
    t.boolean  "notified"
    t.datetime "updated_date"
    t.integer  "id",                          :null => false
  end

  create_table "execution_log", :force => true do |t|
    t.datetime "event_start",                    :null => false
    t.string   "status",          :limit => 32
    t.string   "detailed_status", :limit => 256
    t.string   "updated_by",      :limit => nil
    t.datetime "updated_at"
    t.integer  "r_schedule"
    t.datetime "event_end"
    t.integer  "sla_event_start"
    t.string   "request_id",      :limit => 100
  end

  add_index "execution_log", ["event_start"], :name => "idx_execution_log5"
  add_index "execution_log", ["request_id"], :name => "idx_request_id"
  add_index "execution_log", ["status"], :name => "idx_execution_log4"

  create_table "execution_order", :id => false, :force => true do |t|
    t.integer  "execution_id"
    t.integer  "r_schedule"
    t.integer  "e_order"
    t.string   "status",          :limit => 100
    t.string   "detailed_status"
    t.datetime "event_start"
    t.datetime "event_end"
    t.integer  "sla_event_start"
  end

  add_index "execution_order", ["r_schedule", "e_order"], :name => "IX_order_schedule"

  create_table "job", :force => true do |t|
    t.integer  "job_type_id"
    t.datetime "scheduled_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string   "status",       :limit => 50, :null => false
    t.text     "log"
    t.string   "scheduled_by"
    t.boolean  "recurrent"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "job_entity", :force => true do |t|
    t.integer  "job_id"
    t.string   "r_project"
    t.integer  "r_schedule"
    t.integer  "r_contract"
    t.string   "status",            :limit => 50, :null => false
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.integer  "r_settings_server"
  end

  create_table "job_parameter", :force => true do |t|
    t.integer "job_id"
    t.string  "key",    :null => false
    t.text    "value",  :null => false
  end

  create_table "job_type", :id => false, :force => true do |t|
    t.integer  "id",                       :null => false
    t.string   "name",       :limit => 50, :null => false
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.string   "key"
  end

  create_table "project", :id => false, :force => true do |t|
    t.text     "project_pid",                                              :null => false
    t.text     "status"
    t.text     "name"
    t.text     "ms_person"
    t.string   "updated_by",             :limit => nil
    t.datetime "updated_at"
    t.boolean  "is_deleted",                            :default => false, :null => false
    t.boolean  "sla_enabled"
    t.string   "sla_type",               :limit => 100
    t.string   "sla_value"
    t.datetime "created_at"
    t.string   "customer_name"
    t.string   "customer_contact_name"
    t.string   "customer_contact_email"
    t.integer  "contract_id"
  end

  add_index "project", ["project_pid"], :name => "iidf"
  add_index "project", ["project_pid"], :name => "project_project_pid_key", :unique => true

  create_table "project_detail", :id => false, :force => true do |t|
    t.string   "project_pid",           :null => false
    t.string   "salesforce_type"
    t.string   "practice_group"
    t.text     "note"
    t.string   "solution_architect"
    t.string   "solution_engineer"
    t.string   "confluence"
    t.boolean  "automatic_validation"
    t.string   "tier"
    t.string   "working_hours"
    t.string   "time_zone"
    t.text     "restart"
    t.string   "tech_user"
    t.boolean  "uses_ftp"
    t.boolean  "uses_es"
    t.boolean  "archiver"
    t.string   "sf_downloader_version"
    t.string   "directory_name"
    t.string   "salesforce_id"
    t.string   "salesforce_name"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  create_table "project_history", :force => true do |t|
    t.text     "project_pid"
    t.string   "value",       :limit => 250
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.text     "updated_by"
    t.text     "key"
  end

  create_table "project_history_old", :force => true do |t|
    t.text     "project_pid"
    t.text     "old_value"
    t.text     "new_value"
    t.datetime "updated_at"
    t.text     "updated_by"
    t.text     "key"
  end

  add_index "project_history_old", ["project_pid", "key", "updated_at"], :name => "IX_project_pid_key_updated_at"

  create_table "schedule", :force => true do |t|
    t.string   "graph_name"
    t.string   "mode"
    t.string   "server"
    t.string   "cron"
    t.string   "r_project"
    t.string   "updated_by",         :limit => nil
    t.datetime "updated_at"
    t.boolean  "is_deleted",                        :default => false, :null => false
    t.boolean  "main"
    t.datetime "created_at"
    t.integer  "settings_server_id"
    t.string   "gooddata_schedule"
    t.string   "gooddata_process"
  end

  add_index "schedule", ["graph_name", "r_project", "mode"], :name => "Uniq_r_project_graph_name_mode", :unique => true

  create_table "schedule_history", :force => true do |t|
    t.integer  "schedule_id"
    t.string   "key"
    t.text     "value"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.string   "updated_by"
  end

  create_table "schedule_history_old", :force => true do |t|
    t.text     "r_schedule"
    t.text     "old_value"
    t.text     "new_value"
    t.datetime "updated_at"
    t.text     "updated_by"
    t.text     "key"
  end

  create_table "settings", :force => true do |t|
    t.text     "key"
    t.text     "value"
    t.text     "note"
    t.string   "updated_by", :limit => nil
    t.datetime "updated_at"
  end

  create_table "settings_server", :force => true do |t|
    t.string   "name",        :limit => 50, :null => false
    t.string   "server_url",                :null => false
    t.string   "webdav_url"
    t.string   "server_type",               :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "sla_description", :id => false, :force => true do |t|
    t.integer "id",                                                      :null => false
    t.string  "sla_description_type", :limit => 50,  :default => "None"
    t.string  "sla_description_text", :limit => 200
    t.string  "sla_type",             :limit => 100
    t.string  "sla_value",            :limit => 100
    t.integer "duration",             :limit => 8
  end

  create_table "temp_project_history", :id => false, :force => true do |t|
    t.string  "project_pid"
    t.date    "valid_from"
    t.date    "valid_to"
    t.string  "key",         :limit => 100
    t.string  "value"
    t.integer "h_order"
  end

  create_table "temp_project_history_denorm", :id => false, :force => true do |t|
    t.string  "project_pid"
    t.string  "status",         :limit => 100
    t.boolean "sla_enabled"
    t.string  "sla_type",       :limit => 100
    t.string  "sla_value",      :limit => 100
    t.date    "generated_date"
  end

  create_table "temp_request", :id => false, :force => true do |t|
    t.string "request_id", :limit => 100
  end

end
