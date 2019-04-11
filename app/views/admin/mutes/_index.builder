context.instance_eval do
  column :detail do |mute|
    link_to 'Detail', admin_mute_path(mute), :class => 'link_button'
  end
  column :active, &:active?
  column :reason do |mute|
    truncate(mute.reason, length: 50)
  end
  column :start
  column :end
  column :muted_object do |mute|
    obj = mute.muted_object
    link_to "(#{mute.muted_object_type}) #{obj.name}", polymorphic_path(['admin', obj])
  end
  column :created_by do |mute|
    mute.admin_user ? link_to(mute.admin_user.email, admin_admin_user_path(mute.admin_user)) : 'User missing'
  end
  column 'Manually disabled' do |mute|
    status_tag mute.disabled
    if mute.now_in_range? && authorized?(:edit, mute)
      mute.disabled? ? link_to('Enable', enable_admin_mute_path(mute.id), :class => 'link_button') : link_to('Disable', disable_admin_mute_path(mute.id), :class => 'link_button')
    end
  end
  column :recreate do |mute|
    if authorized?(:create, mute)
      link_to 'Recreate', new_admin_mute_path({:reference_id => mute.reference_id, :reference_type => mute.reference_type, :reason => URI.escape(mute.reason)}), :class => 'link_button'
    end
  end
end