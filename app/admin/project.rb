ActiveAdmin.register Project do
  menu :priority => 8, :parent => 'Resources'
  permit_params :status, :name, :ms_person, :customer_name, :customer_contact_name, :customer_contact_email, :project_pid, :contract_id

  preserve_default_filters!
  filter :status, :as => :select, :collection => %w[Live Paused Suspended]
  filter :contract, :as => :select, :collection => proc { Contract.with_projects.order(:name) }
  remove_filter :running_executions, :project_detail, :mutes, :schedules
  filter :is_deleted, as: :check_boxes

  scope :all, :default => true
  scope :not_muted, :group => :muting
  scope :muted, :group => :muting

  index(row_class: lambda do |c|
    x = []
    x << 'row-highlight-muted' if c.muted?
    x << 'row-highlight-deleted' if c.is_deleted
    x.join(' ')
  end) do |project|
    selectable_column
    column :name do |project|
      link_to project.name, admin_project_path(project) || ''
    end
    column :project_pid
    column :status
    column :updated_at
    column 'Muted?' do |project|
      elements = ''
      status_tag project.muted?
      if project.muted?
        elements += link_to 'Mutes list', admin_mutes_path('q[project_pid_eq]' => project.id.to_s.html_safe, 'commit' => 'Filter')
      else
        elements += link_to 'Mute', new_admin_mute_path(:reference_id => project.send(Project.primary_key.to_sym), :reference_type => Project.name)
      end
      elements.html_safe
    end
    column :detail do |project|
      link_to('Detail', admin_project_detail_path(project.project_pid))
    end
    column :schedules do |project|
      links = ''.html_safe
      links += link_to fa_icon('list-ul lg'), {:controller => 'schedules', :action => 'index', 'q[r_project_contains]' => project.project_pid.to_s.html_safe, 'commit' => 'Filter'}, {:title => 'List schedules for project'}
      links += ' '
      links += link_to fa_icon('plus lg'), {:controller => 'schedules', :action => 'new', :project_pid => project.project_pid},{:title => 'Create new schedule under project'}
      links
    end
  end

  form :validate => true do |f|
    f.inputs 'Info' do
      f.input :project_pid if f.object.new_record?
      f.input :name
      f.input :status, :as => :select2, :collection => %w[Live Development Suspended]
      f.input :ms_person
    end
    f.inputs 'Contact' do
      f.input :contract_id, :as => :select2, :collection => Contract.all.order(:name)
    end
    f.actions
  end

  show do |at|
    if project.muted?
      panel('Project is muted', class: 'panel-muted') do
        span do
          text_node 'This project is currently muted, no notifications will be sent to PagerDuty. Here are the relevant mutes:'
        end
        table_for project.active_mutes do
          column :id do |mute|
            link_to mute.id, admin_mute_path(mute)
          end
          column :reason
          column :start
          column :end
          column :admin_user, :label => 'Muted by'
        end
      end
    end
    columns do
      column :max_width => '350px' do
        panel('Info') do
          attributes_table_for project do
            %i[name status].each do |column|
              row column
            end
            row :updated_by do |p|
              AdminUser.find_by_id(p.updated_by)&.email || 'Unknown'
            end
          end
        end
        panel('Contract') do
          attributes_table_for project do
            row :contract
          end
        end
        panel('Contact') do
          attributes_table_for project do
            %i[customer_name customer_contact_name customer_contact_email].each do |column|
              row column
            end
          end
        end
      end

      column :min_width => '750px', :min_height => '520px' do
        attributes_table do
          text_node %(<iframe frameborder="0" src="https://na1.secure.gooddata.com/dashboard.html?label.sla_project.project_pid=#{params[:id]}#project=/gdc/projects/e30u9871uuqmtqz9053bshwxw0ph6gwf&dashboard=/gdc/md/e30u9871uuqmtqz9053bshwxw0ph6gwf/obj/303014" width="100%" height="470px"></iframe>).html_safe
        end
      end
    end
    panel('History') do
      table_for ProjectHistory.where('project_pid = ?', params['id']) do
        column(:key)
        column(:value)
        column(:updated_by) do |c|
          AdminUser.find_by_id(c.updated_by)&.email || '-'
        end
        column(:created_at)
      end
    end
  end

  action_item :schedules, :only => [:show] do
    link_to 'Schedules', :controller => 'schedules', :action => 'index', 'q[r_project_eq]' => params['id'].to_s.html_safe
  end

  action_item :detail, :only => [:show] do
    link_to('Detail', admin_project_detail_path(params['id']))
  end

  controller do
    include ApplicationHelper

    before_filter :only => [:index] do
      if params['commit'].blank? && params['q'].blank?
        params['q'] = {:is_deleted_in => false}
      end
    end

    def scoped_collection
      end_of_association_chain
    end

    def update
      @project = Project.where('project_pid = ?', params[:id]).first
      public_attributes = Project.get_public_attributes
      ActiveRecord::Base.transaction do
        public_attributes.each do |attr|
          unless same?(params[:project][attr], @project[attr])
            ProjectHistory.add_change(@project.project_pid, attr, params[:project][attr].to_s, current_active_admin_user)
            @project[attr] = params[:project][attr]
          end
        end
        @project.updated_by = current_active_admin_user.id
        if @project.save
          redirect_to admin_project_path(params[:id]), :notice => 'Project was successfully updated.'
        else
          flash[:error] = 'Please review the errors below.'
          render action: 'edit'
        end
      end
    end

    def destroy
      project = Project.where('project_pid = ?', params[:id]).first

      ActiveRecord::Base.transaction do
        ProjectHistory.add_change(project.project_pid, 'is_deleted', 'true', current_active_admin_user)
        project.is_deleted = true
        project.updated_by = current_active_admin_user.id
        project.save
      end
      redirect_to admin_projects_path, :notice => 'Project was deleted!'
    end

    def create
      public_attributes = Project.get_public_attributes
      @project = nil
      begin
        ActiveRecord::Base.transaction do
          @project = Project.new
          @project.project_pid = params[:project]['project_pid']
          @project.updated_by = current_active_admin_user.id
          public_attributes.each do |attr|
            @project[attr] = params[:project][attr]
          end
          if @project.save
            project_detail = ProjectDetail.new
            project_detail.project_pid = @project.project_pid
            project_detail.save!

            redirect_to new_admin_schedule_path(:project_pid => @project.project_pid), :notice => 'Project was successfully created.'
          else
            flash[:error] = 'Please review the errors below.'
            render action: 'edit'
          end
        end
      rescue ActiveRecord::ActiveRecordError => e
        redirect_to new_admin_project_path(params), :flash => {:error => "There was error in creating project - #{e.message}"}
      end
    end
  end
end
