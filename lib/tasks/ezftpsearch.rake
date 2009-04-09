namespace :ezftpsearch do
  desc <<-END_DESC
Run spider to get directory lists of all registered ftp servers or a specified server.
USAGE: rake ezftpsearch:run_spider   -  get dir of all servers
       rake ezftpsearch:run_spider server=server_id - get dir of the server specified by server_id
       rake ezftpsearch:run_spider max_retries=5 - MAX retry count is 5
          (retry is carried out when I can't connect to server or encounter an error)(default is 5)
END_DESC
  task :run_spider => :environment do
    start_time = Time.now
    
    if ENV['server']
      query = "id = '#{ENV['server']}'"
    end
    max_retries = ENV['max_retries'] ? ENV['max_retries'] : 5

    logger = Logger.new(RAILS_ROOT + '/log/ezftpsearch_spider.log', 'monthly')
    logger.info '--------------------------------------------------------------------------------------------------------'
    logger.info '--------------------------------------------------------------------------------------------------------'
    logger.close

    FtpServer.find(:all, :conditions => query).each do |ftp|
      ftp.get_entry_list(max_retries)
    end

    puts 'Task finished in ' + (Time.now - start_time).to_s + ' seconds'
  end

  desc <<-END_DESC
IMPORTANT: ALL FTP ENTRIES WILL BE REMOVED FROM DATABASE!
Reset ftp_entries and swap_ftp_entries tables's auto increment id column,
as a result, the data in the two tables will be removed too.
Since every spider's run will remove old entries in ftp_entries and
swap_ftp_entries and insert new entries in these two tables, the tables'
auto increment id may hit it's limit(INTEGER's limit is 2147483647)
sometime. So you should call this task periodly to reset the tables' id to 1.
NOTE: This task currently only supports MySQL. 
      If you use other type DB, you can modify this task.
USAGE: rake ezftpsearch:clear_entry_and_reset_id SILENT=[true/false]
       SILENT=true means to remove database entries and reset id silently.
       Its default value is false, which means you must confirm to continue.
END_DESC
  task :clear_entry_and_reset_id => :environment do
    if !ENV['SILENT']
      printf "ALL FTP ENTRIES WILL BE REMOVED FROM DATABASE! ARE YOU SURE?(Y/n)"
      exit if !(STDIN.gets.match(/^Y$/i))
    end

    abcs = ActiveRecord::Base.configurations
    case abcs[RAILS_ENV]["adapter"]
      when "mysql"
        FtpEntry.delete_all
        SwapFtpEntry.delete_all
        ActiveRecord::Base.connection.execute("ALTER TABLE ftp_entries AUTO_INCREMENT = 1")
        ActiveRecord::Base.connection.execute("ALTER TABLE swap_ftp_entries AUTO_INCREMENT = 1")
      else
        puts "The " + abcs[RAILS_ENV]["adapter"] + " database adapter is currently not supported."
    end
  end

end