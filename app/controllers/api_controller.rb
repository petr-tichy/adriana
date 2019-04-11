class ApiController < ApplicationController


  def my_logger
    @@my_logger ||= Logger.new("#{Rails.root}/log/my.log")
  end

  def before_save
    my_logger.info("Creating user with name #{self.name}")
  end


  def index
    my_logger.info params


    pp "kokos"
  end

  def feed
    @title = "TEST FEED"
    @notifications = NotificationLog.order("created_at DESC")
    @updated = @notifications.first.created_at unless @notifications.empty?
    respond_to do |format|
      format.atom { render :layout => false }

      # we want the RSS feed to redirect permanently to the ATOM feed
      #format.rss { redirect_to feed_path(:format => :atom), :status => :moved_permanently }
    end

  end


end