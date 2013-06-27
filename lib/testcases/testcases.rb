module SLAWatcher


  class TestCase


    def self.cleartestcases
      ExecutionLog.where(:detailed_status => "FOR TESTING").destroy_all
    end

    def self.testcase1
      cleartestcases
      ExecutionLog.create(:r_schedule => 329, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 5:00:00 UTC"),:event_end => Time.parse("2013-06-10 6:00:00 UTC"))
    end

    def self.testcase2
      cleartestcases
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 5:00:00 UTC"),:event_end => Time.parse("2013-06-10 6:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 6:05:00 UTC"),:event_end => Time.parse("2013-06-10 7:00:00 UTC"))
    end

    def self.testcase3
      cleartestcases
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 5:00:00 UTC"),:event_end => Time.parse("2013-06-10 6:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 6:05:00 UTC"),:event_end => Time.parse("2013-06-10 7:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 7:45:00 UTC"),:event_end => Time.parse("2013-06-10 8:30:00 UTC"))
    end

    def self.testcase4
      cleartestcases
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 5:00:00 UTC"),:event_end => Time.parse("2013-06-10 6:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 6:05:00 UTC"),:event_end => Time.parse("2013-06-10 7:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 7:45:00 UTC"),:event_end => Time.parse("2013-06-10 8:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 8:35:00 UTC"),:event_end => Time.parse("2013-06-10 10:30:00 UTC"))
    end

    def self.testcase5
      cleartestcases
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 5:00:00 UTC"),:event_end => Time.parse("2013-06-10 6:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 6:05:00 UTC"),:event_end => Time.parse("2013-06-10 7:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 7:45:00 UTC"),:event_end => Time.parse("2013-06-10 8:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 17:45:00 UTC"),:event_end => Time.parse("2013-06-10 18:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 18:35:00 UTC"),:event_end => Time.parse("2013-06-10 22:30:00 UTC"))
    end


    def self.testcase6
      cleartestcases
      ExecutionLog.create(:r_schedule => 402, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 5:00:00 UTC"),:event_end => Time.parse("2013-06-10 6:00:00 UTC"))
    end

    def self.testcase7
      cleartestcases
      ExecutionLog.create(:r_schedule => 402, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 5:00:00 UTC"),:event_end => Time.parse("2013-06-10 6:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 402, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 6:05:00 UTC"),:event_end => Time.parse("2013-06-10 7:29:00 UTC"))
    end

    def self.testcase8
      cleartestcases
      ExecutionLog.create(:r_schedule => 402, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 5:00:00 UTC"),:event_end => Time.parse("2013-06-10 6:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 402, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 6:05:00 UTC"),:event_end => Time.parse("2013-06-10 7:29:00 UTC"))
      ExecutionLog.create(:r_schedule => 402, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 7:45:00 UTC"),:event_end => Time.parse("2013-06-10 8:45:00 UTC"))
    end

    def self.testcase9
      cleartestcases
      ExecutionLog.create(:r_schedule => 402, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 5:00:00 UTC"),:event_end => Time.parse("2013-06-10 6:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 402, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 6:05:00 UTC"),:event_end => Time.parse("2013-06-10 7:29:00 UTC"))
      ExecutionLog.create(:r_schedule => 402, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 15:00:00 UTC"),:event_end => Time.parse("2013-06-10 16:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 402, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 16:05:00 UTC"),:event_end => Time.parse("2013-06-10 17:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 402, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 17:35:00 UTC"),:event_end => Time.parse("2013-06-10 18:45:00 UTC"))
    end


    def self.testcase10
      cleartestcases
      ExecutionLog.create(:r_schedule => 402, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 5:00:00 UTC"),:event_end => Time.parse("2013-06-10 6:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 402, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 6:05:00 UTC"),:event_end => Time.parse("2013-06-10 7:29:00 UTC"))
      ExecutionLog.create(:r_schedule => 402, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 15:00:00 UTC"),:event_end => Time.parse("2013-06-10 16:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 402, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 16:05:00 UTC"),:event_end => Time.parse("2013-06-10 17:30:00 UTC"))
    end

    def self.testcase11
      cleartestcases
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-09 5:00:00 UTC"),:event_end => Time.parse("2013-06-09 6:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-09 6:05:00 UTC"),:event_end => Time.parse("2013-06-09 7:29:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-09 7:45:00 UTC"),:event_end => Time.parse("2013-06-09 8:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-09 17:45:00 UTC"),:event_end => Time.parse("2013-06-09 18:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-09 18:35:00 UTC"),:event_end => Time.parse("2013-06-09 22:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 2:45:00 UTC"),:event_end => Time.parse("2013-06-10 4:30:00 UTC"))
    end

    def self.testcase12
      cleartestcases
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 5:00:00 UTC"),:event_end => Time.parse("2013-06-10 6:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 6:05:00 UTC"),:event_end => Time.parse("2013-06-10 7:29:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 7:45:00 UTC"),:event_end => Time.parse("2013-06-10 8:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 17:45:00 UTC"),:event_end => Time.parse("2013-06-10 18:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 18:35:00 UTC"),:event_end => Time.parse("2013-06-10 22:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-11 2:45:00 UTC"),:event_end => Time.parse("2013-06-11 4:30:00 UTC"))
    end


    def self.testcase13
      cleartestcases
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 5:00:00 UTC"),:event_end => Time.parse("2013-06-10 6:00:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 6:05:00 UTC"),:event_end => Time.parse("2013-06-10 7:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 7:45:00 UTC"),:event_end => Time.parse("2013-06-10 8:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 15:45:00 UTC"),:event_end => Time.parse("2013-06-10 16:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'ERROR', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 16:35:00 UTC"),:event_end => Time.parse("2013-06-10 20:30:00 UTC"))
      ExecutionLog.create(:r_schedule => 329, :status => 'FINISHED', :detailed_status => "FOR TESTING",:event_start => Time.parse("2013-06-10 20:35:00 UTC"),:event_end => Time.parse("2013-06-10 21:45:00 UTC"))
    end






  end


end