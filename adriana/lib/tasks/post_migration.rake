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

  $log.info '--- Reloading permissions'
  ::ActiveAdmin::ManagedResource.reload
end
