module Extensions
  module SplunkJob
    def wait
      wait_for_results
    end

    # Override to handle possible timeouts
    def wait_for_results
      wait = 0
      until complete? do
        sleep 1
        wait += 1
        fail 'Splunk search did not return the results after 5 minutes.' if wait >= 300
      end
    end
  end
end
