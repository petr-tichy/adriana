#require 'client_side_validations/formtastic'

#ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
#  unless html_tag =~ /^<label/
#    %{<div class="toto"><div class="field_with_errors">#{html_tag}</div><label for="#{instance.send(:tag_id)}" class="message" style="float:right;">#{instance.error_message.first}</label></div>}.html_safe
#  else
#    %{<div class="toto">#{html_tag}</div>}.html_safe
#  end
#end