module ApplicationHelper
  def same?(first_value, second_value)
    [%w[0 false], %w[1 true]].any? { |x| x == [first_value, second_value].map(&:to_s).sort } ||
    first_value.to_s == second_value.to_s
  end

  def status_tag_extension(p,value)
    if value == 'WAITING'
      p.status_tag value,:warning
    elsif value =='FINISHED' || value =='RUNNING'
      p.status_tag value,:ok
    else
      p.status_tag value,:error
    end
  end

  def extension(value)
    if value == 'WAITING'
      "<span class='status_tag warning'>#{value}</span>".html_safe
    elsif value == 'ERROR'
      "<span class='status_tag error'>#{value}</span>".html_safe
    elsif value =='FINISHED' || value =='OK'
      "<span class='status_tag ok'>#{value}</span>".html_safe
    else
      "<span class='status_tag warning'>#{value}</span>".html_safe
    end
  end
end
