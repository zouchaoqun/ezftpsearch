namespace :ezftpsearch do
  desc 'Run spider to get directory lists of all registered ftp servers.'
  task :run_spider => :environment do
    start_time = Time.now

    FtpServer.find(:all).each do |ftp|
      ftp.get_entry_list
    end

    puts 'finished in ' + (Time.now - start_time).to_s + ' seconds'
  end

  desc <<-END_DESC
IMPORTANT: ALL FTP ENTRIES WILL BE REMOVED FROM DATABASE!
Reset ftp_entries and swap_ftp_entries tables's auto increment id column,
as a result, the data in the two tables will be removed too.
Since every spider's run will remove old entries in ftp_entries and
swap_ftp_entries and insert new entries in these two tables, the tables'
auto increment id may hit it's limit(INTEGER's limit is 2147483647)
sometime. So you should call thistask periodly to reset the tables' id to 1.
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

  desc <<-END_DESC
Update ftp server with the specified name, or create it if the name
does not exist.
Usage:
  rake ezftpsearch:update_server NAME=name HOST=host LOGIN=login \\
        FTP_TYPE=one_of_[Unix,Microsoft,Netware] PASSWORD=password \\
        NOTE=note IGNORED=ingored_dir_list_seperated_by_space \\
        FORCE_UTF8=[true/false] NEW_NAME=new_name_you_want_to_change

  description:
        FORCE_UTF8: Means to send "OPTS UTF8 ON" to ftp server, if your ftp
                    file's name contains non-ASCII characters, this option
                    should be true, else this option should be false.
                    If the ftp server doesn't support this command, you
                    will see an error like "502 Command not implemented".

  requied arguments are:
        NAME, HOST, LOGIN, PASSWORD

  arguments have default value:
        FTP_TYPE: default is Unix
        IGNORED: default is '. .. .svn'
        FORCE_UTF8: default is true
END_DESC
  task :update_server => :environment do
    if !ENV['NAME']
      puts 'Please use rake -D ezftpsearch:update_server to view usage'
      exit
    end
    ftp = FtpServer.find(:first, :conditions => "name = '#{ENV['NAME']}'") || FtpServer.new
    ftp.name = ENV['NAME']
    ftp.name = ENV['NEW_NAME'] if (!ftp.new_record? && ENV['NEW_NAME'])
    ftp.host = ENV['HOST'] if ENV['HOST']
    ftp.login = ENV['LOGIN'] if ENV['LOGIN']
    ftp.password = ENV['PASSWORD'] if ENV['PASSWORD']
    ftp.ftp_type = ENV['FTP_TYPE'] if ENV['FTP_TYPE']
    ftp.ignored_dirs = ENV['IGNORED'] if ENV['IGNORED']
    ftp.note = ENV['NOTE'] if ENV['NOTE']
    ftp.force_utf8 = ENV['FORCE_UTF8'] if ENV['FORCE_UTF8']
    ftp.save!
  end

  desc 'List all registered ftp servers.'
  task :list_servers => :environment do
    FtpServer.find(:all).each do |ftp|
      puts ftp
    end
  end

  desc 'Remove specified ftp server. Usage: rake ezftpsearch:remove_server NAME=name'
  task :remove_server => :environment do
    if !ENV['NAME']
      puts 'Please specify NAME'
      exit
    end
    ftp = FtpServer.find(:first, :conditions => "name = '#{ENV['NAME']}'")
    if !ftp
      puts "Ftp with name:#{ENV['NAME']} not found"
      exit
    end
    printf "Do you really want to REMOVE ftp NAME:#{ftp.name} HOST:#{ftp.host}? (Y/n)"
    exit if !(STDIN.gets.match(/^Y$/i))

    ftp.destroy
  end

end