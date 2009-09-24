module NotesHelper
  def has_more?(arr, num = NotesController::DASHBOARD_ITEM_NUM)
    !!arr[num]
  end

  def wiki_display_name_ipe_option(base={})
    {:messages => {:sending => _("Sending...")}}.merge(base)
  end

  def explain_note(note = current_note)
    opts = {
      :name_key => content_tag("span", _("Note|Name") , :class=>"key"),
      :name_val => content_tag("span", note.name , :class=>"val"),
      :publicity_key => content_tag("span", _("Note|Publicity") , :class=>"key"),
      :publicity_val => content_tag("span", publicity_label(note.publicity) , :class=>"val"),
    }

    _("This note's %{name_key} is '%{name_val}' and %{publicity_key} is '%{publicity_val}'.") % opts
  end

  def explain_note_ext(note = current_note)
    opts = {
      :label_navi_key => content_tag("span", _("Note|Label navigation style"), :class => "key"),
      :label_navi_val => content_tag("span", navi_style_label(note.label_navigation_style), :class => "val"),
      :list_attachments_key => content_tag("span", _("Note|List attachments"), :class => "key"),
      :list_attachments_val => content_tag("span", list_attachments_label(note.list_attachments), :class => "val"),
    }

      _("%{label_navi_key} is %{label_navi_val}, %{list_attachments_key} is %{list_attachments_val}") % opts
  end

  def list_attachments_label(val)
    case val
    when true, 1  then _("List attachment for download.")
    when false, 0 then _("NOT list attachment for download.")
    end
  end

  def explain_users(users)
    spans = users.map{|u| content_tag("span", u.name, :class => "val") }
    user_str = spans.size == 1 ? spans.first : spans[0..-2].join(_(", ")) + _(" and ") + spans.last
    _("%{user_str} are accessible to the note") % {:user_str => user_str }
  end

  def explain_groups(groups)
    spans = groups.map{|g| content_tag("span", g.display_name, :class => "val") }
    group_str = spans[0..-2].join(_(", ")) + _(" and ") + spans.last
    _("%{group_str}'s members are accessible to the note") % {:group_str => group_str }
  end

  def with_last_modified_page(notes, &block)
    ps = Page.active.last_modified_per_notes(notes.map(&:id))
    ret = notes.map{|note| [note, ps.detect{|p| p.note_id == note.id }] }
    block_given? ? ret.each{|n,p| yield n, p } : ret
  end

  def render_wizard(step, key, &block)
    content_for(key, &block)
    concat render(:partial => "wizard", :locals=>{:step=>step, :key=>key})
  end

  def publicity_label(publicity)
    case publicity
    when Note::PUBLICITY_MEMBER_ONLY then _("Access by member only")
    when Note::PUBLICITY_READABLE    then _("Readable by everyone")
    when Note::PUBLICITY_WRITABLE    then _("Readable/Writable by everyone")
    else raise ArgumentError
    end
  end

  def navi_style_label(style)
    case style
    when LabelIndex::NAVIGATION_STYLE_NONE   then _("Not display")
    when LabelIndex::NAVIGATION_STYLE_TOGGLE then _("Display and enable toggle")
    when LabelIndex::NAVIGATION_STYLE_ALWAYS then _("Display always")
    else raise ArgumentError
    end
  end

  def note_operation(selected)
    options_for_select( [
      [_("menu"), nil],
      [_("new page"), new_note_page_path(current_note)],
      [_("show note"), note_path(current_note)],
    ], selected)
  end
end
