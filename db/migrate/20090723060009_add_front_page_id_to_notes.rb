class AddFrontPageIdToNotes < ActiveRecord::Migration
  def self.up
    add_column :notes, :front_page_id, :integer
  end

  def self.down
    remove_column :notes, :front_page_id
  end
end
