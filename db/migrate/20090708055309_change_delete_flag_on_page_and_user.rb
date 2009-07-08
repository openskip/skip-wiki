class ChangeDeleteFlagOnPageAndUser < ActiveRecord::Migration
  def self.up
    add_column :users, :deleted_at, :datetime
    Page.all.each do |p|
      if p.deleted
        p.deleted_at = Time.now
        p.save(false)
      end
    end
    User.all.each do |u|
      if u.deleted
        u.deleted_at = Time.now
        u.save(false)
      end
    end
    remove_column :pages, :deleted
    remove_column :users, :deleted
    remove_column :notes, :deleted_on
  end

  def self.down
    add_column :pages, :deleted, :boolean
    add_column :users, :deleted, :boolean
    add_column :notes, :deleted_on, :datetime
    remove_column :users, :deleted_at
  end
end
