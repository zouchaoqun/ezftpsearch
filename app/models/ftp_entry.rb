class FtpEntry < ActiveRecord::Base
  belongs_to :ftp_server
  acts_as_tree :order => 'name', :counter_cache => :entries_count

  attr_accessor :path

  

end
