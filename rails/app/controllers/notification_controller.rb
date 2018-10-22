class NotificationController < ApplicationController

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