atom_feed :language => 'en-US' do |feed|
  @notifications.each do |notification|
    feed.entry( notification, :url => "www.seznam.cz" ) do |entry|
      # the strftime is needed to work with Google Reader.
      entry.title "kokos1"
      entry.content("<p>Kokosak</p>")
      #entry.title "kokos + N"
      entry.updated(notification.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ"))
      entry.author do |author|
        "Master Blaster"
      end
    end
  end
end