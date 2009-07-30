class DeleteNameFromPages < ActiveRecord::Migration
  def self.up
    remove_column :pages, :name
  end

  def self.down
    add_column :pages, :name, :string, :null => false
    add_index :pages, :name
  end
end
