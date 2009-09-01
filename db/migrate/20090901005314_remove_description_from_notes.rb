class RemoveDescriptionFromNotes < ActiveRecord::Migration
  def self.up
    Note.all.each {|n| n.update_attributes({:display_name => n.display_name + " - " + n.description }) }
    remove_column "notes", "description"
  end

  def self.down
    add_column "notes", "description", :string, :default => "", :null => false
    split_word = " - "
    Note.all.each do |n|
      display_name_position = n.display_name.index(split_word)
      display_name = n.display_name[0...display_name_position]
      description = n.display_name[(display_name_position+split_word.size)..n.display_name.size]
      n.update_attributes({:display_name => display_name, :description => description})
    end
  end
end
