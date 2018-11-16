require_relative '../job_exception'

module PagerdutySynchronizationJob
  class PagerdutySynchronizationJob
    JOB_KEY = 'pagerduty_sync'.freeze
    REQUIRED_PARAMS = %w[resource].freeze

    attr_accessor :job_id, :credentials

    def initialize(job_id, credentials)
      @job_id = job_id
      @credentials = credentials
    end

    def connect
      self.class.connect_to_passman(@credentials[:passman][:address], @credentials[:passman][:port], @credentials[:passman][:key])
    end

    def run
      load_data
      resource = nil
      $log.info "Processing #{JOB_KEY} job: #{@job_id} on server"

      $log.info 'Checking required parameters'
      REQUIRED_PARAMS.each do |rp|
        parameter = @job_parameters.find { |p| p.key == rp }
        if !parameter.nil? && parameter.key.casecmp('resource').zero?
          resource = parameter.value
        elsif parameter.nil?
          raise JobException.new(@job_id, "Missing required parameter: #{rp}")
        end

      end
      $log.info 'All parameters are here'

      # Load password from passman
      $log.info 'Loading resource from Password Manager'
      api_key = PasswordManagerApi::Password.get_password_by_name(resource.split('|')[0], resource.split('|')[1])
      $log.info 'Resource loaded successfully'


      pd = PagerDuty::Full.new(api_key, @subdomain)

      $log.info 'Starting pagerduty notification synchronization'
      @notification_log.each do |notification|
        incidents = pd.Incident.search(nil, notification.pd_event_id, nil, nil, nil, nil, nil)
        incident = incidents['incidents'].first
        next if incident.nil?
        notes = pd.Incident.notes(incident['id'])
        notification.resolved_by = incident['last_status_change_by']['email']
        notification.resolved_at = DateTime.parse(incident['last_status_change_on'])
        notification.note = ''
        if !notes.nil? && !notes['notes'].nil?
          note = notes['notes'].last
          notification.note = note['content'] unless note.nil?
        end
        $log.info "The values for PD event with ID #{notification.pd_event_id} are resolved_by:#{incident['last_status_change_by']['email']} resolved_at:#{notification.resolved_at} with note #{notification.note}"
        notification.save
      end
    end

    #TODO: dry
    def load_data
      # In case of sychronization activity, there is only one entity connected to JOB
      @subdomain = 'gooddata'
      @notification_log = NotificationLog.where(resolved_by: nil).where.not(pd_event_id: nil)
      @job_parameters = JobParameter.where('job_id = ?', @job_id)
      @user = AdminUsers.find_by_email('ms@gooddata.com')
    end

    class << self
      def connect_to_passman(address, port, key)
        PasswordManagerApi::PasswordManager.connect(address, port, key)
      end
    end
  end
end