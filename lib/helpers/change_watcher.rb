module SLAWatcher

  class ChangeWatcher

    attr_accessor :changes

    def initialize(id)
      @id = id
      @changes = []
    end


    def addComparer(comparer)
      @changes.push(comparer)
    end


    def log_changes(log,ident1,ident2,ident3)
      log.info "The #{ident1} #{ident2} (#{ident3}) has been changed"
      different_values.each do |e|
        log.info "#{e.key} - new value: #{e.secondValue} old value:#{e.firstValue}"
      end
      @@log.info "-----------------------------------------------------------------"

    end


    def same?
      @changes.each do |change|
        if (!change.same?)
          return false;
        end
      end
      true
    end

    def same_values
      @changes.find_all{|e| e.same?}
    end

    def different_values
      @changes.find_all{|e| !e.same?}
    end

    def save_history_to_db(table_name)

      if (table_name == "project_history")
        different_values.each do |v|
          ProjectHistory.create(:project_pid => @id,:old_value => v.firstValue, :new_value => v.secondValue,:key => v.key )
        end
      elsif (table_name == "schedule_history")
        different_values.each do |v|
          ScheduleHistory.create(:r_schedule => @id,:old_value => v.firstValue, :new_value => v.secondValue,:key => v.key )
        end
      end



    end



  end


  class Comparer

    attr_accessor :firstValue,:secondValue,:key


    def initialize(firstValue,secondValue,key)
      @firstValue = firstValue
      @secondValue = secondValue
      @key = key
    end

    def same?
      if ((@firstValue.to_s.casecmp(@secondValue.to_s) != 0)) then
        false
      else
        true
      end
    end




  end


end