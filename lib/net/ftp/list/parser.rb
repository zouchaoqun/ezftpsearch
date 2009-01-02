module Net
  class FTP
    module List

      # ParserError
      #
      # Raw entry couldn't be parsed for some reason.
      #
      # == TODO
      #
      # Get more specific with error messages.
      class ParserError < RuntimeError; end

      # Abstract FTP LIST parser.
      #
      # It really just defines and documents the interface.
      #
      # == Exceptions
      #
      # +ParserError+ -- Raw entry could not be parsed.
      class Parser
        # Parse a raw FTP LIST line.
        #
        # By default just takes and set the raw list entry.
        #
        #   Net::FTP::List.parse(raw_list_string, 'ftp_type') # => Net::FTP::List::Parser instance.
        def initialize(raw)
          @raw = raw
        end

        # The raw list entry string.
        def raw
          @raw ||= ''
        end
        alias_method :to_s, :raw

        # The items basename (filename).
        def basename
          @basename ||= ''
        end

        # The item's file size (in byte)
        def file_size
          @file_size ||= 0
        end

        # The item's file datetime
        def file_datetime
          begin
            res = ParseDate.parsedate(@file_datetime)
            Time.local(*res)
          rescue
            puts 'Entry datetime can not be recognized.'
            nil
          end
        end

        # Looks like a directory, try CWD.
        def dir?
          !!@dir ||= false
        end

        # Looks like a file, try RETR.
        def file?
          !!@file ||= false
        end

        # Looks like a symbolic link.
        def symlink?
          !!@symlink ||= false
        end

        class << self
          # Acts as a factory.
          # Factory method.
          #
          # Find a parser by ftp_type and parse a list item.
          # Throw a PaserError exception when encounters a parse error.
          def parse(raw, ftp_type)
            case ftp_type
            when 'Unix' then Unix.new(raw)
            when 'Netware' then Netware.new(raw)
            when 'Microsoft' then Microsoft.new(raw)
            else raise ParserError, 'Invalid ftp type'
            end
          end
          
        end
      end
    end
  end
end
