require_relative '../credentials_helper'

# Expects ready and configured database and valid config/config.json, config/database.yml files linking to the new database
task post_migration: [:environment] do |task|
  $log_file = Rails.root.join('log', "sla_#{task.name}_#{DateTime.now.strftime('%Y%m%d%H%M%S')}.log")
  $log = Logger.new($log_file, 'daily')
  fail 'File config/config.json must be present.' if File.zero?('../../config/config.json')
  begin
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection
    fail unless ActiveRecord::Base.connected?
  rescue StandardError
    fail 'Unable to connect to the database. Check the RAILS_ENV variable and the config/database.yml file.'
  end

  $log.info '--- Running DB migrations'
  Rake::Task['db:migrate'].execute
  fail 'The database is not fully migrated, cannot continue with post_migration task.' if ActiveRecord::Migrator.needs_migration?

  $log.info '--- Marking projects as deleted if not status = Live (status is now deprecated)'
  ActiveRecord::Base.transaction do
    Project.where('status NOT ILIKE ?', 'live').update_all(is_deleted: true)
  end

  $log.info '--- Filling schedule name and process_name for older schedules'
  # Fill Schedule name and process_name for older Schedules
  CredentialsHelper.connect_to_passman(*%w[address port key].map { |x| CredentialsHelper.get("passman_#{x}") })
  contracts_resources = Contract
                          .joins('INNER JOIN job_entity ON job_entity.r_contract = contract.id')
                          .joins('INNER JOIN job on job.id = job_entity.job_id')
                          .joins('INNER JOIN job_parameter ON job_parameter.job_id = job.id')
                          .joins('INNER JOIN settings_server ON settings_server.id = job_entity.r_settings_server')
                          .where('job_parameter.key = \'resource\'')
                          .where('(job_parameter.value = \'\') IS FALSE')
                          .pluck('contract.id', 'job_parameter.value', 'settings_server.server_url').uniq
  contracts_resources.each do |contract_id, resource, resource_server|
    username, password = CredentialsHelper.load_resource_credentials(resource)
    client = GoodData.connect(username, password, server: resource_server)
    schedules = Schedule
                  .joins(:project)
                  .joins(:contract)
                  .where(contract: {id: contract_id})
                  .where.not(gooddata_schedule: '')
                  .pluck(:gooddata_schedule, :name, :process_name, 'project.project_pid').uniq
    schedules.each do |sid, s_name, s_process_name, pid|
      gd_schedule = GoodData::Schedule[sid, project: pid, client: client] rescue next
      schedule_name = gd_schedule.name
      process_name = gd_schedule.process.name
      next if [schedule_name, process_name].any? { |x| x.to_s.empty? }
      next if s_name == schedule_name && s_process_name == process_name
      Schedule.update(sid, name: schedule_name, process_name: process_name)
      $log.info "Updated Schedule #{sid} with values - name: #{schedule_name}, process_name: #{process_name}."
    end
  end
  $log.info '--- Reloading permissions'
  ::ActiveAdmin::ManagedResource.reload
end