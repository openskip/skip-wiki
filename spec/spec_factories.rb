module SpecFactories
  def create_user(options = {})
    record = User.new({:name => "a_user", :display_name => "A User"}.merge(options))
    record.identity_url = "http://openid.example.com/user/"+record.name
    record.save
    record
  end

  def create_note options = {}
    group = mock_model(Group)
    note_valid_attributes = {
      :name => "value_for_name",
      :display_name => "value for display_name",
      :description => "value for description.",
      :publicity => Note::PUBLICITY_MEMBER_ONLY,
      :category_id => "1",
      :owner_group => group,
      :group_backend_type => "BuiltinGroup",
    }.merge(options)
    user = users(:quentin)
    note = NoteBuilder.new(user, note_valid_attributes).note
    note.save!
    note
  end

  def page_valid_attributes
    {
      :last_modied_user_id => "1",
      :name => "value_for_name",
      :display_name => "value for display_name",
      :format_type => "hiki",
      :published => true,
      :deleted_at => Time.now,
      :lock_version => "1"
    }
  end

end
