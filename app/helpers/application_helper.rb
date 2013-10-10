module ApplicationHelper

  def same?(firstValue,secondValue)
    if (firstValue.to_s != secondValue.to_s)
      return false
    else
      return true
    end
  end

  def status_tag_extension(p,value)
    if (value == "WAITING")
      p.status_tag value,:warning
    elsif (value == "FINISHED" or value == "RUNNING")
      p.status_tag value,:ok
    else
      p.status_tag value,:error
    end
  end


end
