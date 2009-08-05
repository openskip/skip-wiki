class Note < ActiveRecord::Base
  extend NamedIdValidation
  PUBLICITY_READABLE = 0
  PUBLICITY_WRITABLE = 1
  PUBLICITY_MEMBER_ONLY = 2

  PUBLIC_CONDITION = ["#{table_name}.publicity IN (:publicity)",
                      {:publicity => [PUBLICITY_READABLE, PUBLICITY_WRITABLE]} ].freeze

  WIZARD_STEPS = [ N_("Select group"), N_("Select category"), N_("Select publicity"),
                   N_("Select label navigation style"), N_("Input name"), N_("Input description"),
                   N_("Select list attachments"), N_("Confirm") ].freeze

  validates_named_id_of :name
  validates_uniqueness_of :name
  validates_presence_of :owner_group, :name, :display_name, :description
  validates_inclusion_of :publicity, :in => (PUBLICITY_READABLE..PUBLICITY_MEMBER_ONLY)

  belongs_to :owner_group, :class_name => "Group"
  belongs_to :category

  has_many :accessibilities
  has_many :label_indices
  has_many :pages, :dependent => :delete_all do
    def add(attrs, user)
      returning(build) do |page|
        content = attrs[:format_type] == "hiki" ? attrs[:content_hiki] : attrs[:content_html]
        page.edit(content, user)
        page.attributes = attrs.except(:content, :content_hiki, :content_html)
        page.label_index_id ||= proxy_owner.default_label.id
        page.attachment_ids = attrs[:attachment_ids] || []
      end
    end
  end

  has_many :attachments, :as => :attachable

  belongs_to :front_page, :class_name => "Page"

  named_scope :free, {:conditions => PUBLIC_CONDITION}

  named_scope :writable_or_accessible, proc{|user|
    return {} if user.blank?
    note_ids = user.accessible_notes.all.map(&:id)
    {
      :conditions => ["#{table_name}.id IN (:note_ids) OR #{table_name}.publicity = :publicity", {:note_ids => note_ids, :publicity => PUBLICITY_WRITABLE}]
    }
  }

  named_scope :readable, {
    :conditions => ["#{table_name}.publicity = :publicity", {:publicity => PUBLICITY_READABLE}]
  }

  named_scope :owned_group, proc{|group|
    return {} unless group
    {:conditions => ["#{table_name}.owner_group_id = (:group_id)", {:group_id => group.id}]}
  }

  named_scope :recent, proc{|*args|
    {
     :order => "#{table_name}.updated_at DESC",
     :limit => args.shift || 10 # default
    }
  }

  named_scope :fulltext, proc{|word|
    return {} if word.blank?
    t = quoted_table_name
    w = "%#{word}%"
    {:conditions => ["#{t}.display_name LIKE ? OR #{t}.description LIKE ?", w, w]}
  }

  attr_writer :group_backend_type
  attr_accessor :group_backend_id

  def group_backend_type
    @group_backend_type || owner_group.backend_type
  end

  def groups=(groups)
    accessibilities.replace groups.map{|g| accessibilities.build(:group=>g) }
  end

  def groups
    accessibilities.map(&:group)
  end

  def public_readable?
    [Note::PUBLICITY_READABLE, Note::PUBLICITY_WRITABLE].include?(publicity)
  end

  def to_param
    name_changed? ? name_was : name
  end

  def default_label
    (label_indices.is_a?(Array) ? label_indices : label_indices.to_a).detect(&:default_label)
  end

  def wikipedia?
    publicity == Note::PUBLICITY_WRITABLE
  end

  def self.wikipedia
    @@wikipedia ||= find_by_publicity(Note::PUBLICITY_WRITABLE)
  end

  def self.create_or_update_wikipedia
    admin_users = User.scoped(:conditions => { :admin => true }).all
    if admin_users.empty?
      ::Rails.logger.info "[INFO] No admin user, wikipedia is not created or updated."
      return nil
    end
    unless wikipedia
      attr = {
        :name => "wikipedia",
        :display_name => "wikipedia",
        :description => "wikipedia",
        :publicity => Note::PUBLICITY_WRITABLE,
        :group_backend_type => "BuiltinGroup",
        # TODO カテゴリどうするのか検討
        :category_id => "1"
      }
      builder = NoteBuilder.new(admin_users.shift, attr)
      builder.note.owner_group.users << admin_users
      builder.note.save!
      builder.note
    else
      # 全部削除してアップデートする
      wikipedia.owner_group.users = admin_users
      wikipedia.owner_group.save!
      wikipedia
    end
  end

  def build_front_page
    pages.build(:label_index_id => label_indices.first.id)
  end

  #TODO 回帰テストを書く
  def attached_file(user)
    note_page_ids = user.accessible_pages.select {|p| p.id if p.note == self }
    Attachment.all(:conditions => ["attachable_id IN (?)", note_page_ids], :order => :attachable_id)
  end
end
