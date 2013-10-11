ActiveAdmin.register Project do

  filter :project_pid
  filter :name
  filter :sla_enabled, :as => :check_boxes, :collection => [true,false]
  filter :sla_type, :as => :select, :collection => ["Fixed Duration","Fixed Time"]
  filter :status, :as => :select, :collection => ["Live","Paused","Suspended"]

  index do |project|
    #last_executions = ExecutionLog.get_last_executions()
    #pp last_executions
    column :name
    column :project_pid
    column :sla_enabled do |project|
      if (project.sla_enabled)
         span(image_tag("true_icon.png",:size => "28x20"))
      else
         span(image_tag("false_icon.png",:size => "20x20"))
      end
    end
    column :sla_type
    column :sla_value
    column :detail do |project|
      link_to('Detail', admin_project_detail_path(project.project_pid))
    end
    column :schedules do |project|
      link_to "Schedules", :controller => "schedules", :action => "index",'q[r_project_eq]' => "#{project.project_pid}".html_safe
    end
    actions
  end

  form do |f|
    f.inputs "Info" do
      f.input :name
      f.input :status, :as => :select, :collection => ["Live", "Development", "Suspended"]
      f.input :ms_person
    end
    f.inputs "SLA" do
      f.input :sla_enabled
      f.input :sla_type, :as => :select, :collection => ["Fixed Duration", "Fixed Time"]
      f.input :sla_value
      # etc
    end
    f.inputs "Contact" do
      f.input :customer_name
      f.input :customer_contact_name
      f.input :customer_contact_email
    end
    f.actions

  end

  show do |at|
    columns do
      column  :max_width => "350px" do
          panel ("Info") do
            attributes_table_for project do
              [:name, :status].each do |column|
                row column
              end
            end

          end

          panel ("SLA") do
            attributes_table_for project do
              [:sla_enabled, :sla_type, :sla_value].each do |column|
                row column
              end
            end
          end

          panel ("Contact") do
            attributes_table_for project do
              [:customer_name, :customer_contact_name, :customer_contact_email,].each do |column|
                row column
              end
            end
          end

      end

      column :min_width => "1000px",:min_height => "490px" do
        attributes_table do
          text_node %{<iframe frameborder="0" src="https://na1.secure.gooddata.com/dashboard.html?label.sla_project.project_pid=#{params[:id]}#project=/gdc/projects/e30u9871uuqmtqz9053bshwxw0ph6gwf&dashboard=/gdc/md/e30u9871uuqmtqz9053bshwxw0ph6gwf/obj/303014" width="100%" height="470px"></iframe>}.html_safe
        end
      end
    end
  end






  controller do
    include ApplicationHelper

    before_filter :only => [:index] do
      if params['commit'].blank?
        params['q'] = {:is_deleted_eq => '0'}
      end
    end

    def update
      project = Project.where("project_pid = ?",params[:id]).first
      public_attributes = Project.get_public_attributes

      ActiveRecord::Base.transaction do
        public_attributes.each do |attr|
          if (!same?(params[:project][attr],project[attr]))
            ProjectHistory.add_change(project.project_pid,attr,params[:project][attr].to_s,current_active_admin_user)
            project[attr] = params[:project][attr]
          end
        end
        project.save
      end

      redirect_to admin_project_path(params[:id])
    end


    def destroy
      project = Project.where("id = ?",params[:id]).first
      project.is_deleted = true
      project.save

      redirect_to admin_project_path,:notice => "Project was deleted!"
    end






  end


end                                   
