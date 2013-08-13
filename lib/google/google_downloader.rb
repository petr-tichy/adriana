require "google_drive"


module SLAWatcher


  class GoogleDownloader


    attr_accessor :session, :spredsheet, :worksheet,:output

    SLA_START = '2013-06-01'


    def initialize(login,password,spredsheet,worksheet)
      @session = GoogleDrive.login(login, password)
      @output = Array.new
      @names = []

      download_spredsheet_by_id(spredsheet)
      create_list_of_sheet_titles
      #set_worksheet(worksheet)

    end


    def download_spredsheet_by_id(id)
      @spredsheet = session.spreadsheet_by_key(id)
    end

    # Returns worksheet
    def find_worksheet_by_name(name)
      worksheet = @spredsheet.worksheet_by_title(name)
      if worksheet.nil?
        worksheet = create_new_worksheet(name)
      end
      worksheet
    end

    def create_new_worksheet(title)
      @spredsheet.add_worksheet(title)
    end

    def set_active_worksheet(worksheet)
      @worksheet = worksheet
    end

    def set_worksheet(index)
        @worksheet = @spredsheet.worksheets[index]
    end

    def create_list_of_sheet_titles
      date = DateTime.new(2013,6,1);
      while (date < DateTime.now)
        @names.push({:date => date,:sheet_name => "#{date.mon}-#{date.year}"})
        date = date + 1.month
      end
    end

    def save
      @names.each do |name|
        find_worksheet_by_name(name[:sheet_name])
        set_active_worksheet(find_worksheet_by_name(name[:sheet_name]))
        @worksheet.save
      end
    end



    def clean_active_worksheet
      @names.each do |name|
        find_worksheet_by_name(name[:sheet_name])
        set_active_worksheet(find_worksheet_by_name(name[:sheet_name]))
        pp @worksheet
        for row in 2..@worksheet.num_rows
          for col in 1..@worksheet.num_cols
            @worksheet[row,col] = ""
          end
        end
      end
    end


    def load_data
      data = []
      @names.each do |name|
        find_worksheet_by_name(name[:sheet_name])
        set_active_worksheet(find_worksheet_by_name(name[:sheet_name]))
        for row in 2..@worksheet.num_rows
          d = {}
          d[:id] = @worksheet[row,1]
          d[:sla_description_type] = @worksheet[row,5]
          d[:sla_description_text] = @worksheet[row,6]
          data.push(d)
        end

      end
      data
    end

    def put_data_to_worksheet(data)

      #SLA ID	Project Name	Project PID	SLA Date	SLA Type	SLA Description
      @names.each do |name|
        find_worksheet_by_name(name[:sheet_name])
        set_active_worksheet(find_worksheet_by_name(name[:sheet_name]))
        sheet_row = 2
        data.each do |d|
          sla_date = DateTime.strptime(d[:event_start],"%Y-%m-%d")
          if (sla_date >= name[:date] and sla_date < name[:date] + 1.month )
            @worksheet[sheet_row,1] = d[:id] #SLA_ID
            @worksheet[sheet_row,2] = d[:project_name]
            @worksheet[sheet_row,3] = d[:project_pid]
            @worksheet[sheet_row,4] = d[:event_start]
            @worksheet[sheet_row,5] = d[:description_type]
            @worksheet[sheet_row,6] = d[:description_text]
            sheet_row = sheet_row + 1
          end
        end
      end
    end


    def fill_error_worksheet

    end

    def load_error_worksheet
      data = []
      set_active_worksheet(find_worksheet_by_name("Error sheet"))
      for row in 2..@worksheet.num_rows
        d = {}
        d[:id] = @worksheet[row,1]
        d[:sla_description_type] = @worksheet[row,5]
        d[:sla_description_text] = @worksheet[row,6]
        data.push(d)
      end


      data
    end





  end

end