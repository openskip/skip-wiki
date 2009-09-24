require 'skip_embedded/web_service_util/server'

class NotesController < ApplicationController
  before_filter :is_wiki_initialized?, :except => %w[new create]
  before_filter :explicit_user_required, :except => %w[new create]
  include SkipEmbedded::WebServiceUtil::Server

  layout :select_layout

  # FIXME なくす
  # GET /notes/1
  # GET /notes/1.xml
  def show
    @note = current_note

    respond_to do |format|
      format.html { redirect_to :controller=>"pages", :action=>"root", :note_id=>@note}
      format.xml  { render :xml => @note }
    end
  end

  # GET /notes/new
  # GET /notes/new.xml
  def new
    @note = Note.new(:group_backend_type=>"BuiltinGroup", :category=>Category.first)

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @note }
    end
  end

  # GET /notes/1/edit
  def edit
    @note = current_note
  end

  # POST /notes
  # POST /notes.xml
  def create
    builder = NoteBuilder.new(current_user, params[:note])
    @note = builder.note

    respond_to do |format|
      begin
        @note.save!
        flash[:notice] = _("Note `%{note}' was successfully created.") % {:note => @note.display_name}
        format.html { redirect_to(note_url(@note)) }
        format.xml  { render :xml => @note, :status => :created, :location => @note }
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
        format.html { render :action => "edit" }
        format.xml  { render :xml => @note.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /notes/1
  # PUT /notes/1.xml
  def update
    @note = current_note
    l=Logger.new("#{RAILS_ROOT}/log/development.log")

    respond_to do |format|
      if @note.update_attributes(params[:note])
        format.html do
          #TODO メッセージの修正
          flash[:notice] = _('Note was successfully updated.') % {:note => @note.display_name }
          redirect_to(:action=>"edit")
        end
        format.xml  { head :ok }
        # TODO Wiki名変更後はリンクにする
        format.js { head(:ok, :location => note_path(current_note)) }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @note.errors, :status => :unprocessable_entity }
        format.js  { render :xml => @note.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /notes/1
  # DELETE /notes/1.xml
  def destroy
    @note = Note.find_by_name(params[:id])
    @note.destroy

    respond_to do |format|
      format.html { redirect_to(notes_url) }
      format.xml  { head :ok }
    end
  end

  private
  def note_to_json(note)
    { :display_name=>note.display_name,
      :link_url=>note_page_path(note, note.front_page),
      :publication_symbols => "note:#{note.id}" }
  end

  def accessible
    if params[:user]
      user = User.find_by_identity_url(params[:user])
    else
      user =current_user
    end
    raise ActiveRecord::RecordNotFound unless user
    user.free_or_accessible_notes
  end

  def select_layout
    case params[:action]
    when *%w[index new] then super
    else "notes"
    end
  end
end
