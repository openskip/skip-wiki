require 'repim/relying_party'
require 'skip_embedded/open_id_sso/session_management'

# This controller handles the login/logout function of the site.
class SessionsController < ApplicationController
  include OpenIdAuthentication
  include Repim::RelyingParty
  include SkipEmbedded::OpenIdSso::SessionManagement
  skip_before_filter :authenticate, :only => %w[new create]

  use_attribute_exchange(["http://axschema.org", "http://schema.openid.net"],
                         :display_name => "/namePerson", :name => "/namePerson/friendly" )

  # SKIPと連携するため基本は必要ない
  def new
    super
    @wiki_nosearchable = true
  end

  def destroy
    super
    flash[:notice] = _("You have been logged out.")
  end

  private
  def login_successfully(*args)
    super
    flash[:notice] = _("Logged in successfully")
  end

  def authenticate_failure(*args)
    super
    flash[:error] = _("Couldn't log you in as '%{openid_url}'") % {:openid_url => assigns[:openid_url] || assigns["openid.claimed_id"]}
  end
end

