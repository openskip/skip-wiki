require 'open-uri'

class SkipGroup < ActiveRecord::Base
  validates_presence_of :name, :gid
  validates_length_of :name, :in=>2..40, :if=>lambda{|r| r.name }
  validates_length_of :gid, :within => 4..50, :if=>lambda{|r| r.gid }

  cattr_reader :site

  has_one  :group, :as => "backend", :dependent => :destroy

  def grant(idurls_or_users)
    if self.group
      group.update_attributes(:name => name, :display_name=>display_name + "(SKIP)")
    else
      create_group(:name=>name, :display_name=>display_name + "(SKIP)")
    end

    users = idurls_or_users.all?{|x| x.is_a?(User) } ?
            idurls_or_users : User.find_all_by_identity_url(idurls_or_users)

    self.group.memberships = users.map{|u| u.memberships.build }
  end

  def self.sync!(data)
    delete_data, keep_or_create_data = data.partition{|d| d[:delete?]}

    indexed_data = delete_data.inject({}){|r, data| r[data[:gid]] = data; r }

    removes = find(:all).select{|g| indexed_data[g.gid] }
    removes.each do |r|
      r.destroy
      indexed_data.delete(r.gid)
    end

    user_cache = User.all.inject({}){|h,u|h[u.identity_url] = u; h }
    indexed_data = keep_or_create_data.inject({}){|r, data| r[data[:gid]] = data; r }
    keeps = find(:all).select{|g| indexed_data[g.gid] }

    keeps.each do |k|
      data = indexed_data.delete(k.gid)
      k.update_attributes!(data.except(:members, :delete?))
      k.grant(data[:members].map{|m| user_cache[m] })
    end

    created = indexed_data.map do |gid, group|
      returning create!(group.except(:members, :delete?)) do |skip_group|
        skip_group.grant( data[:members].map{|k| user_cache[k] } )
        skip_group.create_note!
      end
    end
    [created, keeps, removes]
  end

  def create_note!
    attr = {
      :name => "group_#{name}",
      :display_name => _("%s's wiki") % display_name,
      :publicity => Note::PUBLICITY_READABLE,
      :category_id => "1",
      :group_backend_type => "SkipGroup",
      :group_backend => self.group
    }
    builder = NoteBuilder.new(self, attr)
    builder.note.save!
  end
end

