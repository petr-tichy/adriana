class CreateSettingServerTable < ActiveRecord::Migration
  def change

    create_table "settings_server" do |t|
      t.string  "name", :limit => 50, :null => false
      t.string "server_url",:null => false
      t.string "webdav_url",:null => true
      t.string "type",:null => false
      t.timestamps
    end

    change_table "schedule" do |t|
      t.references :settings_server
    end

    change_table "job_entity" do |t|
      t.integer :r_settings_server
    end

    execute "INSERT INTO settings_server (name,server_url,webdav_url,type,created_at,updated_at) VALUES ('secure','secure.gooddata.com','secure-di.gooddata.com','cloudconnect',now(),now())"
    execute "INSERT INTO settings_server (name,server_url,webdav_url,type,created_at,updated_at) VALUES ('na1','na1.secure.gooddata.com','na1-di.gooddata.com','cloudconnect',now(),now())"
    execute "INSERT INTO settings_server (name,server_url,webdav_url,type,created_at,updated_at) VALUES ('prod2','clover-prod2.ea.getgooddata.com',NULL,'infra',now(),now())"
    execute "INSERT INTO settings_server (name,server_url,webdav_url,type,created_at,updated_at) VALUES ('prod3','clover-prod3.ea.getgooddata.com',NULL,'infra',now(),now())"
    execute "INSERT INTO settings_server (name,server_url,webdav_url,type,created_at,updated_at) VALUES ('dev2','clover-dev2.ea.getgooddata.com',NULL,'bash',now(),now())"

    execute <<-SQL
      UPDATE schedule
	        SET settings_server_id =
			    CASE
            WHEN s.server = 'CloudConnect' then 1
            WHEN s.server = 'clover-prod2' then 3
            WHEN s.server = 'clover-prod3' then 4
            WHEN s.server = 'clover-dev2' then 5
            ELSE 5
			    END
      FROM schedule s
    SQL
  end


end
