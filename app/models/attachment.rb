class Attachment < ActiveRecord::Base
  include ::QuotaValidation
  include ::SkipEmbedded::ValidationsFile

  QUOTA_EACH = QuotaValidation.lookup_setting(self,:each)

  has_attachment :storage => :db_file,
                 :size => 1..QuotaValidation.lookup_setting(self, :each),
                 :processor => :none
  attachment_options.delete(:size) # エラーメッセージカスタマイズのため、自分でバリデーションをかける

  validates_inclusion_of :size, :in => 1..QUOTA_EACH, :message =>
    "#{QUOTA_EACH.to_i/1.megabyte}Mバイト以上のファイルはアップロードできません。"
  validates_quota_of :size, :system, :message =>
    "のシステム全体における保存領域の利用容量が最大値を越えてしまうためアップロードできません。"
  validates_quota_of :size, :per_note, :scope => :attachable_id, :message =>
    "の保存領域の利用容量が最大値を越えてしまうためアップロードできません。"

  belongs_to :attachable, :polymorphic => true
  belongs_to :user

  attr_accessible :display_name, :uploaded_data, :user_id, :attachable_id, :attachable_type

  validates_presence_of :display_name
  validates_as_attachment

  def self.uploading(note, user)
    note.attachments.find(:all, :conditions => {:user_id => user})
  end

  def self.attach(page, user)
    self.uploading(page.note,user).each do |attachment|
      attachment.attachable = page
      attachment.save!
    end
  end

  def filename=(new_name)
    super
    self.display_name = new_name
  end

  def accessible?(notes,pages)
    if self.attachable_type == Note.to_s
      notes.map{ |n| n.id }.include? self.attachable_id
    else
      pages.map{ |p| p.id }.include? self.attachable_id
    end
  end

  def note
    self.attachable_type == Note.to_s ? self.attachable : self.attachable.note
  end

  private
  def validate_on_create
    adapter = ValidationsFileAdapter.new(self)

    valid_extension_of_file(adapter)
    valid_content_type_of_file(adapter)
  end

  def allowed_extention?
    !disallow_extensions.include?(normalized_ext)
  end

  def allowed_content_type?
    !disallow_content_types.include?(content_type.downcase)
  end

  # SKIPのバリデーション内容とあわせる。attachment-fuが提供するテーブルは使わない
  def image_ext_for_image_content_type?
    content_types = CONTENT_TYPE_IMAGES[normalized_ext.to_sym]
    return true unless content_types # not image file.

    return content_types.split(',').include?(content_type)
  end

  def normalized_ext
    File.extname(filename).downcase.sub(/\A^\./, "")
  end
end
