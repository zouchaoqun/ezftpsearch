class EzftpsearchSetup < ActiveRecord::Migration
  def self.up
    create_table :ftp_entries do |t|
      t.column :parent_id, :integer
      t.column :entries_count, :integer, :default => 0, :null => false
      t.column :name, :string, :null => false
      t.column :size, :integer, :limit => 8
      t.column :entry_datetime, :datetime
      t.column :directory, :boolean, :default => false, :null => false
      t.column :ftp_server_id, :integer
    end

    add_index :ftp_entries, :name

    create_table :swap_ftp_entries do |t|
      t.column :parent_id, :integer
      t.column :entries_count, :integer, :default => 0, :null => false
      t.column :name, :string, :null => false
      t.column :size, :integer, :limit => 8
      t.column :entry_datetime, :datetime
      t.column :directory, :boolean, :default => false, :null => false
      t.column :ftp_server_id, :integer
    end

    add_index :swap_ftp_entries, :name

    create_table :ftp_servers do |t|
      t.column :name, :string, :null => false
      t.column :host, :string, :null => false
      t.column :port, :integer, :default => 21, :null => false
      t.column :ftp_type, :string, :default => 'Unix', :null => false
      t.column :ftp_encoding, :string, :default => 'ISO-8859-1'
      t.column :force_utf8, :boolean, :default => false, :null => false
      t.column :login, :string, :null => false
      t.column :password, :string, :null => false
      t.column :ignored_dirs, :string, :default => ". .. .svn"
      t.column :note, :text
      t.column :in_swap, :boolean, :default => true, :null => false
      t.column :updated_on, :timestamp
#todo
#add entry count
    end

    create_table :ezftpsearch_log do |t|
      t.column :type, :string, :null => false
      t.column :log, :string, :null => false
      t.column :created_on, :timestamp
    end

  end

  def self.down
    drop_table :ftp_entries
    drop_tabel :swap_ftp_entries
    drop_table :ftp_servers
    drop_table :ezftpsearch_log
  end
end
