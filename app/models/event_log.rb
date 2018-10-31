class EventLog < ActiveRecord::Base
  self.table_name = 'event_log'
  private

  #TODO params
  def person_params
    params.permit(:event_entity,:severity, :key, :updated_date, :persistent, :event_type, :notified, :text, :created_date)
  end

end