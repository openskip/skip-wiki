class ChangePublishedDefaultFalseToPages < ActiveRecord::Migration
  def self.up
    change_column_default :pages, :published, false
  end

  def self.down
    change_column_default :pages, :published, true
  end
end
