class Admin::GroupsController < Admin::ApplicationController
  layout "admin"

  def show 
    @group = Group.find(params[:id])  
    @note = @group.owning_note
    @topics = [[_("note"), admin_notes_path],
               ["#{@note.display_name}", edit_admin_note_path(@note)],
                _("group users")]    
    @child = true
  end
end
