require_relative 'splunk_results'

module SplunkSynchronizationJob
  class SplunkJob
    REQUEST_LIMIT = 4
    REQUEST_WAIT_TIME = 40

    attr_accessor :job_id, :client, :succeeded

    def initialize(job_id, client_pointer)
      @job_id = job_id
      @client = client_pointer # SplunkClient object pointer
      @succeeded = false
    end

    # Polls on the results endpoint and blocks until results are available
    # @return [Boolean] Returns true if the job succeeded, false if failed.
    def poll_for_results
      # Wait for the Splunk search to complete
      request_count = 0
      until completed?
        if (request_count += 1) >= REQUEST_LIMIT
          return @succeeded = false
        end
        sleep REQUEST_WAIT_TIME
      end

      @succeeded = !failed?
    end

    def cancel
      @client.control_job(@job_id, 'cancel')
    end

    # When the job is done, there will be a field with isDone = 1 (doesn't mean it succeeded)
    def completed?
      @client.get_search_done_status(@job_id).to_s.casecmp('true').zero?
    end

    # If the job finished and failed, there will be a field with isFailed = 1
    def failed?
      @client.get_search_failed_status(@job_id).to_s.casecmp('true').zero?
    end

    def results(max_results = 50_000)
      unless @succeeded
        raise SplunkSearchError, @client.get_search_messages(@job_id).to_s
      end

      # Return search results
      offset = 0
      results = []
      loop do
        current_results = JSON.parse(@client.get_search_results(@job_id, max_results, offset).body).dig('results')
        results.concat(current_results) if current_results&.any?
        break if results.nil? || results.empty? || results.size < max_results
        offset += max_results
      end
      results
    end

    def parsed_results
      SplunkResults.new(results).results
    end
  end
end