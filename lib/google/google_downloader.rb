require "google_drive"


module SLAWatcher


  class GoogleDownloader


    attr_accessor :session, :spredsheet, :worksheet,:output


    def initialize(login,password,spredsheet,worksheet)
      @session = GoogleDrive.login(login, password)
      @output = Array.new

      download_spredsheet_by_id(spredsheet)
      set_worksheet(worksheet)

    end


    def download_spredsheet_by_id(id)
      @spredsheet = session.spreadsheet_by_key(id)
    end

    def set_worksheet(index)
        @worksheet = @spredsheet.worksheets[index]
    end


    def save
      @worksheet.save
    end



    def clean_active_worksheet

      for row in 2..@worksheet.num_rows
        for col in 1..@worksheet.num_cols
          @worksheet[row,col] = ""
        end
      end
    end


    def load_data
      data = []
      for row in 2..@worksheet.num_rows
        d = {}
        d[:id] = @worksheet[row,1]
        d[:sla_description_type] = @worksheet[row,5]
        d[:sla_description_text] = @worksheet[row,6]
        data.push(d)
      end
      data
    end

    def put_data_to_worksheet(data)
      #SLA ID	Project Name	Project PID	SLA Date	SLA Type	SLA Description
      sheet_row = 2
      data.each do |d|
        @worksheet[sheet_row,1] = d[:id] #SLA_ID
        @worksheet[sheet_row,2] = d[:project_name]
        @worksheet[sheet_row,3] = d[:project_pid]
        @worksheet[sheet_row,4] = d[:event_start]
        @worksheet[sheet_row,5] = d[:description_type]
        @worksheet[sheet_row,6] = d[:description_text]
        sheet_row = sheet_row + 1
      end



    end


    def load_projects(columns)
      for row in 2..@worksheet.num_rows
        row_hash = Hash.new
        columns.each do |col|
          column_number = get_column_id(col)
          row_hash[col] = @worksheet[row,column_number]
        end
        @output.push(row_hash)
      end
    end

    def get_column_id(name)
      for col in 1..@worksheet.num_cols
          if (@worksheet[1,col] == name) then
            return col
          end
      end
    end


  end

end