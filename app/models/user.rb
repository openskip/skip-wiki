class User < ActiveRecord::Base
  include SkipEmbedded::LogicalDestroyable
  extend NamedIdValidation
  attr_accessor :batch_mode
  attr_protected :identity_url, :batch_mode

  validates_named_id_of     :name
  validates_presence_of     :display_name, :identity_url
  validates_uniqueness_of   :name, :identity_url, :unless => :batch_mode
  validates_length_of       :display_name, :within => 1..60

  has_many :memberships, :dependent => :destroy do
    def replace_by_type(klass, *groups)
      remains = find(:all, :include=>:group).select{|m| m.group.backend_type != klass.name }
      news = groups.map{|g| proxy_reflection.klass.new(:group=>g,:user=>proxy_owner) }
      replace(remains + news)
    end
  end
  has_many :groups, :through => :memberships
  has_many :builtin_groups, :foreign_key => "owner_id"

  has_many :client_applications
  has_many :tokens, :class_name => "OauthToken", :order => "authorized_at DESC", :include => [:client_application], :dependent => :destroy

  has_many :attachments

  scope_do :named_acl
  named_acl :notes

  named_scope :fulltext, proc{|word|
    return {} if word.blank?
    # TODO
    # quoted_table_nameの概要を諸橋さんに聞く
    # [ActiveRecord]
    # def self.quoted_table_name
    #   self.connection.quote_table_name(self.table_name)
    # end
    w = "%#{word}%"
    {:conditions => ["name LIKE ? OR display_name LIKE ?", w, w]}
  }

  def after_logical_destroy
    tokens.delete_all
  end

  # TODO 複雑なのでリファクタする
  def self.sync!(skip, users_update_data)
    delete_data, keep_or_create_data = users_update_data.partition{|d| d[:delete?]}

    id2var = delete_data.inject({}) do |r, data|
      r[data[:identity_url]] = data; r
    end

    removes = find(:all).select{|u| id2var[u.identity_url] }
    removes.each do |r|
      r.logical_destroy
      delete_data.delete_if {|d| d[:identity_url] == r.identity_url}
    end
    delete_data.each do |d|
      user = create!(d.except(:delete?)) do |u|
        u.identity_url = d[:identity_url]
      end
      user.logical_destroy
      removes << user
    end

    id2var = keep_or_create_data.inject({}) do |r, data|
      r[data[:identity_url]] = data; r
    end

    keeps = find(:all).select{|u| id2var[u.identity_url] }
    keeps.each do |k|
      k.update_attributes!(id2var.delete(k.identity_url).except(:delete?))
      skip.publish_access_token(k) unless k.access_token_for(skip)
    end
    created = id2var.map{|_id_,var| create_with_token!(skip, var.except(:delete?)){|u|u.batch_mode=true}.first }
    Note.create_or_update_wikipedia
    [created, keeps, removes]
  end

  def create_note!
    attr = {
      :name => "user_#{name}",
      :display_name => _("%s's wiki") % display_name,
      :publicity => Note::PUBLICITY_READABLE,
      :category_id => "1",
      :group_backend_type => "BuiltinGroup"
    }
    builder = NoteBuilder.new(self, attr)
    builder.note.save!
  end

  def self.create_with_token!(skip, user_param)
    u = create!(user_param) do |u|
      yield u if block_given?
      u.identity_url = user_param[:identity_url]
    end
    u.create_note!
    return [u, skip.publish_access_token(u)]
  end

  def name=(value)
    write_attribute :name, (value ? value.downcase : nil)
  end

  def page_editable?(note)
    note.wikipedia? || accessible?(note)
  end

  def note_editable?(note)
    # TODO wikipediaのbuildin_groupsにadminユーザ飲みが入るならばaccessible?だけで良いはず
    note.wikipedia? ? admin? : accessible?(note)
  end


  def build_note(note_params)
    NoteBuilder.new(self, note_params).note
  end

  def access_token_for(app)
    tokens.detect{|t| t.is_a?(AccessToken) && t.client_application_id == app.id }
  end

  # TODO 回帰テストを書く
  def accessible_pages(group = nil)
    writable_or_accessible_note_ids =
      if group
        Note.writable_or_accessible(self).owned_group(group).all.map(&:id)
      else
        Note.writable_or_accessible(self).all.map(&:id)
      end
    readable_note_ids =
      if group
        Note.readable.owned_group(group).all.map(&:id)
      else
        Note.readable.all.map(&:id)
      end

    Page.active.scoped({
      :conditions => [
        "(#{Page.quoted_table_name}.note_id IN (:writable_or_accessible_note_ids)) OR (#{Page.quoted_table_name}.note_id IN (:readable_note_ids) AND #{Page.quoted_table_name}.published = :published)",
        {:writable_or_accessible_note_ids => writable_or_accessible_note_ids, :readable_note_ids => readable_note_ids, :published => true}]
    })
  end

  def accessible_attachment?(attachment)
    if attachment.attachable_type == Note.to_s
      self.free_or_accessbile_notes.map{ |n| n.id }.include? attachment.attachable_id
    else
      self.accessible_pages.map{ |p| p.id }.include? attachment.attachable_id
    end
  end
end

