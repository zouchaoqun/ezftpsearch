class FtpServer < ActiveRecord::Base
  has_many :ftp_entries
  has_many :swap_ftp_entries

  validates_presence_of :name, :host, :ftp_type, :port, :login, :password

  def get_entry_list
    require 'net/ftp'
    begin
      BasicSocket.do_not_reverse_lookup = true

      puts "trying ftp #{name} on #{host}"
      ftp = Net::FTP.open(host, login, password)
      if in_swap
        FtpEntry.delete_all(["ftp_server_id=?", id])
      else
        SwapFtpEntry.delete_all(["ftp_server_id=?", id])
      end
      get_list_of(ftp)
      ftp.close
      self.in_swap = !in_swap
      save
    rescue => detail
      puts detail
    end
  end

  def to_s
    "id:#{id} NAME:#{name} HOST:#{host} FTP_TYPE:#{ftp_type} LOGIN:#{login}
     PASSWORD:#{password} IGNORED:#{ignored_dirs} NOTE:#{note}"
  end

private
  def get_list_of(ftp, parent_entry = nil)
    puts "get list start \t" + Time.now.strftime("%H:%S.") + Time.now.tv_usec.to_s
    ic = Iconv.new('UTF-8', ftp_encoding) if force_utf8
    puts "after ic.new \t" + Time.now.strftime("%H:%S.") + Time.now.tv_usec.to_s

    entry_list = parent_entry ? ftp.list(parent_entry.path) : ftp.list
    puts "after ftp.list \t" + Time.now.strftime("%H:%S.") + Time.now.tv_usec.to_s
    entry_list.each do |e|
      entry = Net::FTP::List.parse(e, ftp_type)
      puts "after parse \t" + Time.now.strftime("%H:%S.") + Time.now.tv_usec.to_s

      puts entry.basename
      if (entry.basename.include?("09"))
        aa = entry.basename
        xx = ic.iconv(aa)
      end
      
      next if ignored_dirs.include?(entry.basename)

      entry_param = {:parent => parent_entry,
                     :name => force_utf8 ? ic.iconv(entry.basename) : entry.basename,
                     :size => entry.file_size,
                     :entry_datetime => entry.file_datetime,
                     :directory => entry.dir?}
      if (in_swap)
        ftp_entry = ftp_entries.create(entry_param)
      else
        ftp_entry = swap_ftp_entries.create(entry_param)
      end

      puts "after save \t" + Time.now.strftime("%H:%S.") + Time.now.tv_usec.to_s

      ftp_entry.path = (parent_entry ? parent_entry.path : '') + '/' + entry.basename

      if entry.dir?
        get_list_of(ftp, ftp_entry)
      end
    end
  end
end
