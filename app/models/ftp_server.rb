class FtpServer < ActiveRecord::Base
  has_many :ftp_entries, :dependent => :delete_all
  has_many :swap_ftp_entries, :dependent => :delete_all

  validates_presence_of :name, :host, :ftp_type, :port, :login, :password

  def to_s
    "id:#{id} NAME:#{name} HOST:#{host} FTP_TYPE:#{ftp_type} LOGIN:#{login}
     PASSWORD:#{password} IGNORED:#{ignored_dirs} NOTE:#{note}"
  end

  def get_entry_list(max_retries = 5)
    require 'net/ftp'
    require 'logger'
    @max_retries = max_retries.to_i
    BasicSocket.do_not_reverse_lookup = true
    @entry_count = 0

    # Trying to open ftp server, exit on max_retries
    retries_count = 0
    begin
      @logger = Logger.new(RAILS_ROOT + '/log/ezftpsearch_spider.log', 'monthly')
      @logger.formatter = Logger::Formatter.new
      @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
      @logger.info("Trying ftp server #{name} (id=#{id}) on #{host}")
      ftp = Net::FTP.open(host, login, password)
    rescue => detail
      retries_count += 1
      @logger.error("Open ftp exception: " + detail.class.to_s + " detail: " + detail.to_s)
      @logger.error("Retrying #{retries_count}/#{@max_retries}.")
      if (retries_count >= @max_retries)
        @logger.error("Retry reach max times, now exit.")
        @logger.close
        exit
      end
      ftp.close if !ftp.closed?
      @logger.error("Wait 30s before retry open ftp")
      sleep(30)
      retry
    end

    # Trying to get ftp entry-list
    get_list_retries = 0
    begin
      ftp.passive = true
      @logger.info("Server connected")
      start_time = Time.now
      # Before get list, delete old ftp entries if there are any
      if in_swap
        FtpEntry.delete_all(["ftp_server_id=?", id])
        @logger.info("Old ftp entries in ftp_entry deleted before get entries")
      else
        SwapFtpEntry.delete_all(["ftp_server_id=?", id])
        @logger.info("Old ftp entries in swap_ftp_entry deleted before get entries")
      end
      get_list_of(ftp)
      self.in_swap = !in_swap
      save
      # After table swap, delete old ftp entries to save db space
      if in_swap
        FtpEntry.delete_all(["ftp_server_id=?", id])
        @logger.info("Old ftp entries in ftp_entry deleted after get entries")
      else
        SwapFtpEntry.delete_all(["ftp_server_id=?", id])
        @logger.info("Old ftp entries in swap_ftp_entry deleted after get entries")
      end

      process_time = Time.now - start_time
      @logger.info("Finish getting list of server " + name + " in " + process_time.to_s + " seconds.")
      @logger.info("Total entries: #{@entry_count}. #{(@entry_count/process_time).to_i} entries per second.")
    rescue => detail
      get_list_retries += 1
      @logger.error("Get entry list exception: " + detail.class.to_s + " detail: " + detail.to_s)
      @logger.error("Retrying #{get_list_retries}/#{@max_retries}.")
      raise if (get_list_retries >= @max_retries)
      retry
    ensure
      ftp.close if !ftp.closed?
      @logger.info("Ftp connection closed.")
      @logger.close
    end
  end

private
  # get entries under parent_path, or get root entries if parent_path is nil
  def get_list_of(ftp, parent_path = nil, parent_id = nil)
    ic = Iconv.new('UTF-8', ftp_encoding) if force_utf8
    ic_reverse = Iconv.new(ftp_encoding, 'UTF-8') if force_utf8

    retries_count = 0
    begin
      entry_list = parent_path ? ftp.list(parent_path) : ftp.list
    rescue => detail
      retries_count += 1
      @logger.error("Ftp LIST exception: " + detail.class.to_s + " detail: " + detail.to_s)
      @logger.error("Retrying get ftp list #{retries_count}/#{@max_retries}")
      raise if (retries_count >= @max_retries)
      
      reconnect_retries_count = 0
      begin
        ftp.close if !ftp.closed?
        @logger.error("Wait 30s before reconnect")
        sleep(30)
        ftp.connect(host)
        ftp.login(login, password)
      rescue => detail2
        reconnect_retries_count += 1
        @logger.error("Reconnect ftp failed, exception: " + detail2.class.to_s + " detail: " + detail2.to_s)
        @logger.error("Retrying reconnect #{reconnect_retries_count}/#{@max_retries}")
        raise if (reconnect_retries_count >= @max_retries)
        retry
      end
      
      @logger.error("Ftp reconnected!")
      retry
    end

    entry_list.each do |e|
      # Some ftp will send 'total nn' string in LIST command
      # We should ignore this line
      next if /^total/.match(e)

puts "#{@entry_count} #{e}"

      if force_utf8
        begin
          e_utf8 = ic.iconv(e)
        rescue Iconv::IllegalSequence
          @logger.error("Iconv::IllegalSequence, file ignored. raw data: " + e)
          next
        end
      end
      entry = Net::FTP::List.parse(force_utf8 ? e_utf8 : e, ftp_type)

      next if ignored_dirs.include?(entry.basename)

      @entry_count += 1

      file_datetime = entry.file_datetime.strftime("%Y-%m-%d %H:%M:%S")
      sql = "insert into #{in_swap ? 'ftp_entries' : 'swap_ftp_entries'}"
      sql +=  " (parent_id,name,size,entry_datetime,directory,ftp_server_id)"
      entry_basename = entry.basename.gsub("'","''")
      sql += " VALUES (#{parent_id || 0},'#{entry_basename}',#{entry.file_size},'#{file_datetime}',#{entry.dir? ? 1 : 0},#{id})"

      entry_id = ActiveRecord::Base.connection.insert(sql)
      if entry.dir?
        ftp_path = (parent_path ? parent_path : '') + '/' +
                          (force_utf8 ? ic_reverse.iconv(entry.basename) : entry.basename)
        get_list_of(ftp, ftp_path, entry_id)
      end

    end
  end

end
