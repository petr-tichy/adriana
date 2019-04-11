ActiveAdmin.register ProjectDetail do
  menu false
  permit_params :salesforce_type, :practice_group, :note, :solution_architect,
                :solution_engineer, :confluence, :automatic_validation, :tier,
                :working_hours, :time_zone, :restart, :tech_user, :uses_ftp,
                :uses_es, :archiver, :sf_downloader_version, :directory_name,
                :salesforce_id, :salesforce_name
  actions :all, :except => [:new,:create,:destroy]

  form do |f|
    f.inputs "Overview" do
      f.input :salesforce_type
      f.input :practice_group
      f.input :note
      f.input :solution_architect
      f.input :solution_engineer
      f.input :confluence
    end
    f.inputs "Customer" do
      f.input :working_hours
      f.input :time_zone
      # etc
    end
    f.inputs "Technical details" do
      f.input :restart
      f.input :tech_user
      f.input :uses_ftp
      f.input :uses_es
      f.input :archiver
      f.input :sf_downloader_version
    end

    f.inputs "Integration" do
      f.input :salesforce_id
      f.input :salesforce_name
    end
    f.actions

  end

  show do |at|
    columns do
      column  do
        panel ("Overview") do
          attributes_table_for project_detail do
            [:salesforce_type, :practice_group, :note, :solution_architect,:solution_engineer,:confluence].each do |column|
              row column
            end
          end
        end

        panel ("Customer") do
          attributes_table_for project_detail do
            [:tier, :working_hours, :time_zone].each do |column|
              row column
            end
          end
        end
      end

      column do

        panel ("Technical details") do
          attributes_table_for project_detail do
            [:restart, :tech_user, :uses_ftp,:uses_es,:archiver,:sf_downloader_version].each do |column|
              row column
            end
          end
        end

        panel ("Integration") do
          attributes_table_for project_detail do
            [:salesforce_id, :salesforce_name].each do |column|
              row column
            end
          end
        end
      end
    end
  end

  controller do

  end
end