ActiveAdmin.register Project do

  filter :project_pid
  filter :name
  filter :status, :as => :select, :collection => ["Live","Paused","Suspended"]
  filter :contract_id,:as => :select, :collection => Contract.all

  index do |project|
    #last_executions = ExecutionLog.get_last_executions()
    #pp last_executions
    column :name
    column :project_pid
    column :status
    column :detail do |project|
      link_to('Detail', admin_project_detail_path(project.project_pid))
    end
    column :schedules do |project|
      links = ''.html_safe
      links += link_to "List", :controller => "schedules", :action => "index",'q[r_project_contains]' => "#{project.project_pid}".html_safe,'commit' => "Filter"
      links += " "
      links += link_to "New", :controller => "schedules", :action => "new",:project_pid =>  project.project_pid
      links
    end
    actions
  end

  form :validate => true do |f|
    f.inputs "Info" do
      if f.object.new_record?
        f.input :project_pid
      end
      f.input :name
      f.input :status, :as => :select, :collection => ["Live", "Development", "Suspended"]
      f.input :ms_person
    end
    f.inputs "Contact" do
      f.input :contract_id, :as => :select,:collection => Contract.all(:order => "name")
    end
    f.actions

  end

  show do |at|
    columns do
      column  :max_width => "350px" do
          panel ("Info") do
            attributes_table_for project do
              pp project
              [:name, :status].each do |column|
                row column
              end
              row :updated_by do |p|
                AdminUser.find(p.updated_by).email || "Unknown"
              end
            end

          end
          panel ("Contact") do
            attributes_table_for project do
              [:customer_name, :customer_contact_name, :customer_contact_email].each do |column|
                row column
              end
            end
          end

      end

      column :min_width => "750px",:min_height => "520px" do
        attributes_table do
          text_node %{<iframe frameborder="0" src="https://na1.secure.gooddata.com/dashboard.html?label.sla_project.project_pid=#{params[:id]}#project=/gdc/projects/e30u9871uuqmtqz9053bshwxw0ph6gwf&dashboard=/gdc/md/e30u9871uuqmtqz9053bshwxw0ph6gwf/obj/303014" width="100%" height="470px"></iframe>}.html_safe
        end
      end
    end
  end

  action_item :only => [:show] do
    link_to "Schedules", :controller => "schedules", :action => "index",'q[r_project_eq]' => "#{params["id"]}".html_safe
  end

  action_item :only => [:show] do
    link_to('Detail', admin_project_detail_path(params["id"]))
  end



  controller do
    include ApplicationHelper

    before_filter :only => [:index] do
      if params['commit'].blank? and params['q'].blank?
        params['q'] = {:is_deleted_eq => '0'}
      elsif !params['q'].blank?
        params['q'].merge!({:is_deleted_eq => '0'})
      end
    end


    #def resource
    #  @project = Project.where(project_pid: params[:id])
    #end

    #def new
    #  @project = Project.new(params[:project]) if (!params[:project].nil?)
    #  pp params
    #  new!
    #end



    def update
      project = Project.where("project_pid = ?",params[:id]).first
      public_attributes = Project.get_public_attributes
      pp params
      ActiveRecord::Base.transaction do
        public_attributes.each do |attr|
          if (!same?(params[:project][attr],project[attr]))
            ProjectHistory.add_change(project.project_pid,attr,params[:project][attr].to_s,current_active_admin_user)
            project[attr] = params[:project][attr]
          end
        end
        project.updated_by = current_active_admin_user.id
        project.save
      end

      redirect_to admin_project_path(params[:id])
    end



    def destroy
      project = Project.where("project_pid = ?",params[:id]).first

      ActiveRecord::Base.transaction do
        ProjectHistory.add_change(project.project_pid,"is_deleted","true",current_active_admin_user)
        project.is_deleted = true
        project.updated_by = current_active_admin_user.id
        project.save
      end
      redirect_to admin_projects_path,:notice => "Project was deleted!"
    end


    def create
      public_attributes = Project.get_public_attributes
      project = nil
      begin
        ActiveRecord::Base.transaction do
          project = Project.new()
          project.project_pid = params[:project]["project_pid"]
          project.updated_by = current_active_admin_user.id
          public_attributes.each do |attr|
            project[attr] =  params[:project][attr]
          end
          project.save!

          project_detail = ProjectDetail.new()
          project_detail.project_pid = project.project_pid
          project_detail.save!

          public_attributes.each do |attr|
            ProjectHistory.add_change(project.project_pid,attr,params[:project][attr].to_s,current_active_admin_user)
          end
        end
        #redirect_to admin_project_path(project.id),:notice => "Project was created successfully"
        redirect_to new_admin_schedule_path(:project_pid =>  project.project_pid),:notice => "Project was created successfully"
      rescue ActiveRecord::ActiveRecordError => e
        redirect_to new_admin_project_path(params),:flash => { :error => "There was error in creating project - #{e.message}" }
      end

    end






  end


end                                   
