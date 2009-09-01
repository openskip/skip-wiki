class AttachmentsController < ApplicationController
  include IframeUploader
  include ActionView::Helpers::NumberHelper # to format file size on JSON

  before_filter :writable_user_required, :only => %w[new create destroy]
  before_filter :only_if_list_attachments_or_group_member, :only => %w[index list]
  before_filter :accessible_attachment, :only => %w[show]

  def index
    if params[:page_id]
      page = current_user.accessible_pages.find(params[:page_id])
      @attachments = page.attachments.
        find(:all, :order =>"#{Attachment.quoted_table_name}.updated_at DESC")
    else
      @attachments = Attachment.uploading(current_note, current_user)
    end

    respond_to do |format|
      format.html do
        ajax_upload? ? render(:text => "") : render
      end
      format.js do
        render :json => @attachments.map{|a| {:attachment=>attachment_to_json(a)} }
      end
    end
  end

  def show
    opts = {:filename => @attachment.display_name, :type => @attachment.content_type }
    opts[:filename] = URI.encode(@attachment.display_name) if msie?
    opts[:disposition] = "inline" if params[:position] == "inline"

    send_data(@attachment.send(:current_data), opts)
  end

  def new
    @attachment = if params[:page_id]
                    Page.new.attachments.build(:attachable_id => params[:page_id])
                  else
                    current_note.attachments.build
                  end
  end

  def create
    params[:attachment].merge!(:user_id => current_user.id)
    @attachment = Attachment.new(params[:attachment])
    if @attachment.save
      opt = ajax_upload? ? IframeUploader.index_opt : {}
      redirect_to note_attachments_url(current_note, opt)
    else
      logger.warn(@attachment.errors.full_messages)
      if ajax_upload?
        render :template => "attachments/validation_error"
      else
        render :action => "new"
      end
    end
  end

  def destroy
    @attachment.destroy
    flash[:notice]= _("Deleted %{name}") %
          {:name => "#{_("Attachment")} #{@attachment.display_name}"}

    redirect_to(note_page_path(@attachment.attachable.note, @attachment.attachable))
  end

  def list
    @attachments = current_note.attached_file(current_user)
  end

  private
  def attachment_to_json(atmt)
    returning(atmt.attributes.slice("content_type", "filename", "display_name")) do |json|
      json[:path] = attachment_path(atmt)
      json[:inline] = attachment_path(atmt, :position=>"inline") if atmt.image?
      # TODO I18n::MissingTranslationData (translation missing: ja, number, human, storage_units, format):
#      json[:size] = number_to_human_size(atmt.size)
      json[:size] = atmt.size

      json[:updated_at] = atmt.updated_at.strftime("%Y/%m/%d %H:%M")
      json[:created_at] = atmt.created_at.strftime("%Y/%m/%d %H:%M")
    end
  end

  def select_layout
    return "application" unless signed_in?
    ajax_upload? ? "iframe_upload" : "notes"
  end

  def only_if_list_attachments_or_group_member
    unless (current_user.page_editable?(current_note) || current_note.list_attachments)
      head(:forbidden)
    end
  end

  def writable_user_required
    unless current_user.page_editable?(current_note||attachment.note)
      head(:forbidden)
    end
  end

  def accessible_attachment
    unless current_user.accessible_attachment?(attachment)
      head(:forbidden)
    end
  end

  def attachment
    @attachment ||= Attachment.find(params[:id])
  end
end
