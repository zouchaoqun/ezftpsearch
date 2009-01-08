class FtpServer < ActiveRecord::Base
  has_many :ftp_entries
  has_many :swap_ftp_entries

  validates_presence_of :name, :host, :ftp_type, :port, :login, :password

  def get_entry_list
    require 'net/ftp'
    begin
      BasicSocket.do_not_reverse_lookup = true

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
      puts detail.class
    end
  end

  def to_s
    "id:#{id} NAME:#{name} HOST:#{host} FTP_TYPE:#{ftp_type} LOGIN:#{login}
     PASSWORD:#{password} IGNORED:#{ignored_dirs} NOTE:#{note}"
  end

private
  def get_list_of(ftp, parent_entry = nil)
    ic = Iconv.new('UTF-8', ftp_encoding) if force_utf8
    ic_reverse = Iconv.new(ftp_encoding, 'UTF-8') if force_utf8

    entry_list = parent_entry ? ftp.list(parent_entry.path) : ftp.list
    entry_list.each do |e|
      if force_utf8
        begin
          e_utf8 = ic.iconv(e)
        rescue Iconv::IllegalSequence
          puts "Iconv::IllegalSequence, file ignored. raw data: " + e
          next
        end
      end
      entry = Net::FTP::List.parse(force_utf8 ? e_utf8 : e, ftp_type)

      next if ignored_dirs.include?(entry.basename)

      entry_param = {:parent => parent_entry,
                     :name => entry.basename,
                     :size => entry.file_size,
                     :entry_datetime => entry.file_datetime,
                     :directory => entry.dir?}
      if (in_swap)
        ftp_entry = ftp_entries.create(entry_param)
      else
        ftp_entry = swap_ftp_entries.create(entry_param)
      end

      if entry.dir?
        ftp_entry.path = (parent_entry ? parent_entry.path : '') + '/' +
                          (force_utf8 ? ic_reverse.iconv(entry.basename) : entry.basename)
        get_list_of(ftp, ftp_entry)
      end
    end
  end
end
