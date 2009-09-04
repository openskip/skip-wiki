# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'repim/application'
require 'skip_embedded/open_id_sso/authentication'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  helper_method :current_note

  include Repim::Application
  include SkipEmbedded::OpenIdSso::Authentication

  init_gettext("skip-note") if defined? GetText
  before_filter { Time.zone = "Asia/Tokyo" }

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '77b5db0ea0fa2d0a22f4fe4a123d699e'

  rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found

  layout :select_layout

  private
  def select_layout
    "application"
  end

  def msie?(version = 6)
    !!(request.env["HTTP_USER_AGENT"]["MSIE #{version}"])
  end

  def explicit_user_required
    # TODO 回帰テストを書く
    # TODO 引数のパラメータは正しくないかも。アクセスされる全ての箇所でnote_idがない場合idがnote_idであることを前提としている
    self.current_note = current_user.free_or_accessible_notes.find_by_name(params[:note_id]||params[:id])
    unless current_note and current_user.page_editable?(current_note)
      render_not_found
    end
  end

  def is_wiki_initialized?
    if @note = current_note and @note.pages.size == 0 and current_user.note_editable?(@note)
      @note = current_note
      @page = @note.build_front_page
      flash.now[:notice] = _("Let's make top page first.")
      render :template => "pages/init", :layout => "notes"
    end
  end

  def current_note=(note)
    @__current_note = note
  end

  # Get current note inside of nested controller.
  def current_note
    return nil if @__current_note == :none
    return @__current_note if @__current_note

    scope = logged_in? ? current_user.free_or_accessible_notes : Note.free
    @__current_note = @note || scope.find_by_name(params[:note_id]||params[:id]) || :none
    current_note
  end

  def authenticate_with_session_or_oauth
    if oauthenticate
      self.current_user = @current_user # oauth plugin assigns '@current_user' but we use '@__current_user__'
      signed_in? ? true : invalid_oauth_response
    else
      authenticate
    end
  end

  def authenticate_with_oauth
    if oauthenticate
      self.current_user = @current_user # oauth plugin assigns '@current_user' but we use '@__current_user__'
      return true
    else
      logger.info "failed oauthenticate"
      invalid_oauth_response
    end
  end

  def paginate_option(target = Note)
    { :page => params[:page],
      :order => "#{target.quoted_table_name}.updated_at DESC",
      :per_page => params[:per_page] || 10,
    }
  end

  def render_not_found(e = nil)
    e.backtrace.each{|m| logger.debug m } if e
    render :template => "shared/not_found", :status => :not_found, :layout => false
  end

  # Override Repim's to translate message and specify signup layout.
  def access_denied_without_open_id_sso(message = nil)
    store_location
    flash[:error] = _("Login required.")
    respond_to do |format|
      format.html{ render :template => "sessions/new", :layout => "application", :status => :unauthorized }
      format.rss { render :text => "Unauthorized", :status => :unauthorized }
    end
  end

  def authenticate_with_api_or_login_required
    params[:user].blank? ? authenticate_with_session_or_oauth : check_secret_key
  end

end
