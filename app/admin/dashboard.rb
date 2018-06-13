ActiveAdmin.register_page "Dashboard" do
  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  content :title => proc{ I18n.t("active_admin.dashboard") } do
    panel "Overview" do
      render 'overview'
    end
  end

  controller do
    def index
      @schedules = Schedule.all.count
    end
  end
end
