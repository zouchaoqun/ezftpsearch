class FtpServer < ActiveRecord::Base
  has_many :ftp_entries, :dependent => :delete_all
  has_many :swap_ftp_entries, :dependent => :delete_all

  validates_presence_of :name, :host, :ftp_type, :port, :login, :password

  def to_s
    "id:#{id} NAME:#{name} HOST:#{host} FTP_TYPE:#{ftp_type} LOGIN:#{login}
     PASSWORD:#{password} IGNORED:#{ignored_dirs} NOTE:#{note}"
  end

#  def get_entry_list_with_retry
#    require 'net/ftp'
#    require 'logger'
#
#  end

  def get_entry_list
    require 'net/ftp'
    require 'logger'
    begin
      start_time = Time.now
      @logger = Logger.new(RAILS_ROOT + '/log/ezftpsearch_spider.log', 'monthly')
      @logger.info("Trying ftp server " + name + " on " + host)
      BasicSocket.do_not_reverse_lookup = true
      ftp = Net::FTP.open(host, login, password)
      ftp.passive = true
      @logger.info("Server connected")
      if in_swap
        FtpEntry.delete_all(["ftp_server_id=?", id])
        @logger.info("Old ftp entries in ftp_entry deleted")
      else
        SwapFtpEntry.delete_all(["ftp_server_id=?", id])
        @logger.info("Old ftp entries in swap_ftp_entry deleted")
      end
      get_list_of(ftp)
      ftp.close
      self.in_swap = !in_swap
      save
      process_time = Time.now - start_time
      @logger.info("Finish getting list of server " + name + " in " + process_time.to_s + " seconds.")
    rescue => detail
      puts detail.class
      puts detail
      @logger.error("Exception caught " + detail.class.to_s + " detail: " + detail.to_s)
    ensure
      @logger.close
    end
  end
  
private
  def get_list_of(ftp, parent_entry = nil)
    ic = Iconv.new('UTF-8', ftp_encoding) if force_utf8
    ic_reverse = Iconv.new(ftp_encoding, 'UTF-8') if force_utf8

    retries_count = 0
    begin
      entry_list = parent_entry ? ftp.list(parent_entry.path) : ftp.list
    rescue => detail
      retries_count += 1
      @logger.error("Ftp LIST exception " + detail.class.to_s + " detail: " + detail.to_s)
      @logger.error("Retrying #{retries_count}/5")
      raise if (retries_count > 4)
      
      reconnect_retries_count = 0
      begin
        ftp.close if !ftp.closed?
        @logger.error("Wait 30s before reconnect")
        sleep(30)
        ftp.connect(host)
        ftp.login(login, password)
      rescue
        reconnect_retries_count += 1
        @logger.error("Reconnect to ftp, still exception " + detail.class.to_s + " detail: " + detail.to_s)
        @logger.error("Retrying reconnect #{reconnect_retries_count}/5")
        raise if (reconnect_retries_count > 4)
        retry
      end
      
      @logger.error("Reconnected!")
      retry
    end

    entry_list.each do |e|
puts e
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
#sleep(1)
        ftp_entry.path = (parent_entry ? parent_entry.path : '') + '/' +
                          (force_utf8 ? ic_reverse.iconv(entry.basename) : entry.basename)
        get_list_of(ftp, ftp_entry)
      end
    end
  end
end
