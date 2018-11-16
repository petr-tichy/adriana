require_relative 'contract_synchronization_job/contract_synchronization_job'
require_relative 'direct_synchronization_job/direct_synchronization_job'
require_relative 'pagerduty_synchronization_job/pagerduty_synchronization_job'
require_relative 'restart_job/restart_job'

module JobHelper
  REGISTERED_JOBS = [
    ContractSynchronizationJob::ContractSynchronizationJob,
    DirectSynchronizationJob::DirectSynchronizationJob,
    PagerdutySynchronizationJob::PagerdutySynchronizationJob,
    RestartJob::RestartJob
  ].freeze

  class << self
    def get_job_by_name(name)
      job_class = REGISTERED_JOBS.find { |x| x.const_get(:JOB_KEY) == name }
      job_class.tap { |x| fail "The specified job '#{name}' is not available." if x.nil? }
    end
  end
end