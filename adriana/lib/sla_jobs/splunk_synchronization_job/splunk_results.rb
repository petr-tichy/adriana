require_relative 'splunk_result'

module SplunkSynchronizationJob
  class SplunkResults
    attr_reader :results

    def initialize(raw_results)
      @results = raw_results.empty? ? [] : raw_results.map { |r| SplunkResult.new(r) }
    end
  end
end