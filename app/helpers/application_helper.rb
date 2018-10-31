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

  def extension(value)
    if (value == "WAITING")
      "<span class='status_tag warning'>#{value}</span>".html_safe
    elsif (value == "ERROR")
      "<span class='status_tag error'>#{value}</span>".html_safe
    elsif (value == "FINISHED" or value == "OK")
      "<span class='status_tag ok'>#{value}</span>".html_safe
    else
      "<span class='status_tag warning'>#{value}</span>".html_safe
    end
  end



end
