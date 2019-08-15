module ActiveAdmin::ViewHelpers

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