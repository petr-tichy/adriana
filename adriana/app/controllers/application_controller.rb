class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :set_timezone

  private
  def set_timezone
    Time.zone = cookies['time_zone']
  end

end
