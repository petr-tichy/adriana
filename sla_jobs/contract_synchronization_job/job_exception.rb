class JobException < Exception
  attr_accessor :message, :job_id

  def initialize(job_id,message)
    @job_id = job_id
    @message = message
  end
end

