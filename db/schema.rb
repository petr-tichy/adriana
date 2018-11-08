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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181107142734) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "resource_id",   limit: 255, null: false
    t.string   "resource_type", limit: 255, null: false
    t.integer  "author_id"
    t.string   "author_type",   limit: 255
    t.text     "body"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "namespace",     limit: 255
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
    t.index ["resource_type", "resource_id"], name: "index_admin_notes_on_resource_type_and_resource_id", using: :btree
  end

  create_table "active_admin_managed_resources", force: :cascade do |t|
    t.string "class_name", null: false
    t.string "action",     null: false
    t.string "name"
    t.index ["class_name", "action", "name"], name: "active_admin_managed_resources_index", unique: true, using: :btree
  end

  create_table "active_admin_permissions", force: :cascade do |t|
    t.integer "managed_resource_id",                       null: false
    t.integer "role",                limit: 2, default: 0, null: false
    t.integer "state",               limit: 2, default: 0, null: false
    t.index ["managed_resource_id", "role"], name: "active_admin_permissions_index", unique: true, using: :btree
  end

  create_table "admin_users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.integer  "role",                   limit: 2,   default: 0,  null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree
  end

  create_table "contract", force: :cascade do |t|
    t.string   "name",                         limit: 50,  default: "Empty contract", null: false
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
    t.boolean  "is_deleted",                               default: false
    t.integer  "customer_id"
    t.string   "updated_by",                   limit: 255
    t.boolean  "sla_enabled",                              default: false
    t.string   "sla_type",                     limit: 255
    t.string   "sla_value",                    limit: 255
    t.integer  "sla_percentage"
    t.boolean  "monitoring_enabled",                       default: false
    t.string   "monitoring_emails",            limit: 255
    t.integer  "monitoring_treshhold"
    t.string   "salesforce_id",                limit: 50
    t.string   "contract_type",                limit: 50,  default: "N/A"
    t.string   "token",                        limit: 255
    t.string   "documentation_url",            limit: 255
    t.string   "resource",                     limit: 255
    t.integer  "default_max_number_of_errors",             default: 0
  end

  create_table "contract_history", force: :cascade do |t|
    t.integer  "contract_id"
    t.string   "value",       limit: 250
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.text     "updated_by"
    t.text     "key"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "customer", force: :cascade do |t|
    t.string   "name",           limit: 50,  default: "Empty customer", null: false
    t.string   "email",          limit: 255
    t.string   "contact_person", limit: 255
    t.datetime "created_at",                                            null: false
    t.datetime "updated_at",                                            null: false
    t.boolean  "is_deleted",                 default: false
    t.string   "updated_by",     limit: 255
  end

  create_table "customer_history", force: :cascade do |t|
    t.integer  "customer_id"
    t.string   "value",       limit: 250
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.text     "updated_by"
    t.text     "key"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "dump_log", force: :cascade do |t|
    t.string   "project_pid", limit: 100
    t.string   "graph_name",  limit: 255
    t.string   "mode",        limit: 255
    t.text     "text"
    t.string   "updated_by",  limit: 100
    t.datetime "updated_at"
    t.string   "schedule_id", limit: 255
    t.index ["id"], name: "IX__dump_log_id", using: :btree
  end

  create_table "error_filter", force: :cascade do |t|
    t.string   "message",       limit: 255
    t.integer  "admin_user_id"
    t.boolean  "active",                    default: true
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.index ["admin_user_id"], name: "index_error_filter_on_admin_user_id", using: :btree
  end

  create_table "event_log", force: :cascade do |t|
    t.string   "project_pid",  limit: 100
    t.string   "graph_name",   limit: 100
    t.string   "mode",         limit: 255
    t.integer  "severity"
    t.string   "event_type",   limit: 255
    t.text     "text"
    t.datetime "created_date"
    t.boolean  "persistent"
    t.boolean  "notified"
    t.datetime "updated_date"
    t.string   "key",          limit: 255
    t.string   "event_entity", limit: 100
    t.string   "pd_event_id",  limit: 255
  end

  create_table "execution_log", force: :cascade do |t|
    t.datetime "event_start",                                       null: false
    t.string   "status",                limit: 32
    t.string   "detailed_status",       limit: 256
    t.string   "updated_by",            limit: 255
    t.datetime "updated_at"
    t.integer  "r_schedule"
    t.datetime "event_end"
    t.integer  "sla_event_start"
    t.string   "request_id",            limit: 100
    t.string   "pd_event_id",           limit: 255
    t.text     "error_text"
    t.boolean  "matches_error_filters",             default: false
    t.index ["event_start"], name: "idx_execution_log5", using: :btree
    t.index ["id", "r_schedule"], name: "idx_execution_r_schedule", using: :btree
    t.index ["request_id"], name: "idx_request_id", using: :btree
    t.index ["status"], name: "idx_execution_log4", using: :btree
  end

  create_table "execution_order", id: false, force: :cascade do |t|
    t.integer  "execution_id"
    t.integer  "r_schedule"
    t.integer  "e_order"
    t.string   "status",          limit: 100
    t.string   "detailed_status", limit: 255
    t.datetime "event_start"
    t.datetime "event_end"
    t.integer  "sla_event_start"
    t.index ["r_schedule", "e_order"], name: "IX_order_schedule", using: :btree
  end

  create_table "job", force: :cascade do |t|
    t.integer  "job_type_id"
    t.datetime "scheduled_at"
    t.string   "scheduled_by", limit: 255
    t.boolean  "recurrent"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "cron",         limit: 255
    t.boolean  "is_disabled",              default: false
  end

  create_table "job_entity", force: :cascade do |t|
    t.integer  "job_id"
    t.string   "r_project",         limit: 255
    t.integer  "r_schedule"
    t.integer  "r_contract"
    t.string   "status",            limit: 50,  null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "r_settings_server"
  end

  create_table "job_history", force: :cascade do |t|
    t.integer  "job_id"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string   "status",      limit: 255
    t.text     "log"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "job_parameter", force: :cascade do |t|
    t.integer "job_id"
    t.string  "key",    limit: 255, null: false
    t.text    "value",              null: false
  end

  create_table "job_type", id: false, force: :cascade do |t|
    t.integer  "id",                     null: false
    t.string   "name",       limit: 50,  null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "key",        limit: 255
  end

  create_table "mute", force: :cascade do |t|
    t.text     "reason"
    t.datetime "start"
    t.datetime "end"
    t.integer  "admin_user_id"
    t.integer  "contract_id"
    t.string   "project_pid",   limit: 255
    t.integer  "schedule_id"
    t.boolean  "disabled",                  default: false
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.index ["admin_user_id"], name: "index_mute_on_admin_user_id", using: :btree
    t.index ["contract_id"], name: "index_mute_on_contract_id", using: :btree
    t.index ["project_pid"], name: "index_mute_on_project_pid", using: :btree
    t.index ["schedule_id"], name: "index_mute_on_schedule_id", using: :btree
  end

  create_table "notification_log", force: :cascade do |t|
    t.string   "key",               limit: 255, null: false
    t.string   "notification_type", limit: 50,  null: false
    t.string   "pd_event_id",       limit: 100
    t.integer  "severity",                      null: false
    t.string   "subject",           limit: 255
    t.text     "message"
    t.text     "note"
    t.string   "resolved_by",       limit: 255
    t.datetime "resolved_at"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "project", id: false, force: :cascade do |t|
    t.text     "project_pid",                                        null: false
    t.text     "status"
    t.text     "name"
    t.text     "ms_person"
    t.string   "updated_by",             limit: 255
    t.datetime "updated_at"
    t.boolean  "is_deleted",                         default: false, null: false
    t.boolean  "sla_enabled"
    t.string   "sla_type",               limit: 100
    t.string   "sla_value",              limit: 255
    t.datetime "created_at"
    t.string   "customer_name",          limit: 255
    t.string   "customer_contact_name",  limit: 255
    t.string   "customer_contact_email", limit: 255
    t.integer  "contract_id"
    t.index ["project_pid"], name: "iidf", using: :btree
    t.index ["project_pid"], name: "project_project_pid_key", unique: true, using: :btree
  end

  create_table "project_detail", id: false, force: :cascade do |t|
    t.string   "project_pid",           limit: 255, null: false
    t.string   "salesforce_type",       limit: 255
    t.string   "practice_group",        limit: 255
    t.text     "note"
    t.string   "solution_architect",    limit: 255
    t.string   "solution_engineer",     limit: 255
    t.string   "confluence",            limit: 255
    t.boolean  "automatic_validation"
    t.string   "tier",                  limit: 255
    t.string   "working_hours",         limit: 255
    t.string   "time_zone",             limit: 255
    t.text     "restart"
    t.string   "tech_user",             limit: 255
    t.boolean  "uses_ftp"
    t.boolean  "uses_es"
    t.boolean  "archiver"
    t.string   "sf_downloader_version", limit: 255
    t.string   "directory_name",        limit: 255
    t.string   "salesforce_id",         limit: 255
    t.string   "salesforce_name",       limit: 255
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  create_table "project_history", force: :cascade do |t|
    t.text     "project_pid"
    t.string   "value",       limit: 250
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.text     "updated_by"
    t.text     "key"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "project_history_old", force: :cascade do |t|
    t.text     "project_pid"
    t.text     "old_value"
    t.text     "new_value"
    t.datetime "updated_at"
    t.text     "updated_by"
    t.text     "key"
    t.index ["project_pid", "key", "updated_at"], name: "IX_project_pid_key_updated_at", using: :btree
  end

  create_table "running_executions", force: :cascade do |t|
    t.integer  "schedule_id"
    t.string   "status",                      limit: 255
    t.string   "detailed_status",             limit: 255
    t.string   "request_id",                  limit: 255
    t.datetime "event_start",                                         null: false
    t.datetime "event_end"
    t.integer  "number_of_consequent_errors",             default: 0
  end

  create_table "schedule", force: :cascade do |t|
    t.string   "graph_name",           limit: 255
    t.string   "mode",                 limit: 255
    t.string   "server",               limit: 255
    t.string   "cron",                 limit: 255
    t.string   "r_project",            limit: 255
    t.string   "updated_by",           limit: 255
    t.datetime "updated_at"
    t.boolean  "is_deleted",                       default: false, null: false
    t.boolean  "main",                             default: false
    t.datetime "created_at"
    t.integer  "settings_server_id"
    t.string   "gooddata_schedule",    limit: 255
    t.string   "gooddata_process",     limit: 255
    t.integer  "max_number_of_errors",             default: 0
  end

  create_table "schedule_history", force: :cascade do |t|
    t.integer  "schedule_id"
    t.string   "key",         limit: 255
    t.text     "value"
    t.datetime "valid_from"
    t.datetime "valid_to"
    t.string   "updated_by",  limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "schedule_history_old", force: :cascade do |t|
    t.text     "r_schedule"
    t.text     "old_value"
    t.text     "new_value"
    t.datetime "updated_at"
    t.text     "updated_by"
    t.text     "key"
  end

  create_table "settings", force: :cascade do |t|
    t.text     "key"
    t.text     "value"
    t.text     "note"
    t.string   "updated_by", limit: 255
    t.datetime "updated_at"
  end

  create_table "settings_server", force: :cascade do |t|
    t.string   "name",            limit: 50,  null: false
    t.string   "server_url",      limit: 255, null: false
    t.string   "webdav_url",      limit: 255
    t.string   "server_type",     limit: 255, null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "default_account", limit: 255
  end

  create_table "sla_description", id: false, force: :cascade do |t|
    t.integer "id",                                                null: false
    t.string  "sla_description_type", limit: 50,  default: "None"
    t.string  "sla_description_text", limit: 200
    t.string  "sla_type",             limit: 100,                  null: false
    t.string  "sla_value",            limit: 100
    t.bigint  "duration"
    t.string  "contract_id",          limit: 10
  end

  create_table "sla_description_contract", id: false, force: :cascade do |t|
    t.integer "id",                                 null: false
    t.string  "sla_description_type",   limit: 100
    t.string  "sla_description_text",   limit: 100
    t.string  "sla_type",               limit: 100
    t.string  "sla_value",              limit: 10
    t.integer "duration"
    t.string  "sla_percentage",         limit: 10
    t.string  "sla_achieved",           limit: 10
    t.string  "contract_id",            limit: 10
    t.string  "generated_date",         limit: 50
    t.integer "number_failed_projects"
    t.integer "projects_per_contract"
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type", limit: 255
    t.integer  "tagger_id"
    t.string   "tagger_type",   limit: 255
    t.string   "context",       limit: 128
    t.datetime "created_at"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  end

  create_table "tags", force: :cascade do |t|
    t.string  "name",           limit: 255
    t.integer "taggings_count",             default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true, using: :btree
  end

  create_table "temp_contract_history", id: false, force: :cascade do |t|
    t.string  "contract_id", limit: 255
    t.date    "valid_from"
    t.date    "valid_to"
    t.string  "key",         limit: 100
    t.string  "value",       limit: 255
    t.integer "h_order"
  end

  create_table "temp_contract_history_denorm", id: false, force: :cascade do |t|
    t.string  "contract_id",    limit: 255
    t.boolean "sla_enabled"
    t.string  "sla_type",       limit: 100
    t.string  "sla_value",      limit: 100
    t.string  "sla_percentage", limit: 100
    t.string  "salesforce_id",  limit: 100
    t.string  "contract_type",  limit: 100
    t.date    "generated_date"
  end

  create_table "temp_project_history", id: false, force: :cascade do |t|
    t.string  "project_pid", limit: 255
    t.date    "valid_from"
    t.date    "valid_to"
    t.string  "key",         limit: 100
    t.string  "value",       limit: 255
    t.integer "h_order"
  end

  create_table "temp_project_history_denorm", id: false, force: :cascade do |t|
    t.string  "project_pid",    limit: 255
    t.string  "status",         limit: 100
    t.boolean "sla_enabled"
    t.string  "sla_type",       limit: 100
    t.string  "sla_value",      limit: 100
    t.integer "contract_id"
    t.date    "generated_date"
  end

  create_table "temp_request", id: false, force: :cascade do |t|
    t.string "request_id", limit: 100
  end

end
