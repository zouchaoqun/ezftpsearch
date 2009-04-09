class RemoveEntriesCount < ActiveRecord::Migration
  def self.up
    remove_column :ftp_entries, :entries_count
    remove_column :swap_ftp_entries, :entries_count
  end

  def self.down
    add_column :ftp_entries, :entries_count, :integer, :default => 0, :null => false
    add_column :swap_ftp_entries, :entries_count, :integer, :default => 0, :null => false
  end
end
