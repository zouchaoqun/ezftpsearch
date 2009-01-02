require File.join(File.dirname(__FILE__), 'list/parser')
require File.join(File.dirname(__FILE__), 'list/unix')
require File.join(File.dirname(__FILE__), 'list/microsoft')
require File.join(File.dirname(__FILE__), 'list/netware')

module Net #:nodoc:
  class FTP #:nodoc:

    # Parse FTP LIST responses.
    #
    # == Creation
    #
    #   require 'net/ftp' # Not really required but I like to list dependencies sometimes.
    #   require 'net/ftp/list'
    #
    #   ftp = Net::FTP.open('somehost.com', 'user', 'pass')
    #   ftp.list('/some/path') do |e|
    #     entry = Net::FTP::List.parse(e, 'Unix')
    #
    #     # Ignore everything that's not a file (so symlinks, directories and devices etc.)
    #     next unless entry.file?
    #
    #     # If entry isn't a kind_of Net::FTP::List::Unknown then there is a bug in Net::FTP::List if this isn't the
    #     # same name as ftp.nlist('/some/path') would have returned.
    #     puts entry.basename
    #   end
    #
    # == Exceptions
    #
    # None at this time. At worst you'll end up with an Net::FTP::List::Unknown instance which won't have any extra
    # useful information. Methods like <tt>dir?</tt>, <tt>file?</tt> and <tt>symlink?</tt> will all return +false+.
    module List
      def self.parse(*args)
        Parser.parse(*args)
      end
    end
  end
end

