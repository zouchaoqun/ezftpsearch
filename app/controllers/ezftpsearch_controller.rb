# ezFTPSearch plugin for redMine
# Copyright (C) 2008-2009  Zou Chaoqun
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class EzftpsearchController < ApplicationController
  unloadable

  helper :sort
  include SortHelper

  layout 'base'
  before_filter :find_project, :authorize
  before_filter :check_params, :only => [:search]

  def index
    @ftp_servers = FtpServer.find(:all)
  end

  def search
    server_id_list = Array.new
    swap_server_id_list = Array.new

    @checked_servers = []
    servers = FtpServer.find(:all)
    for server in servers
      if (params[server.id.to_s] == "1")
        if (server.in_swap)
          swap_server_id_list.insert(-1, server.id)
        else
          server_id_list.insert(-1, server.id)
        end
        @checked_servers.insert(-1, server.id)
      end
    end

    @ftp_question = params[:fq] || ""
    @ftp_question.strip!
    @tokens = @ftp_question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect {|m| '%' + m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '') + '%'}
    @tokens = @tokens.uniq.select {|w| !w.include?('%%') }

    @process_time = Benchmark.realtime() do
      if !@tokens.empty?
        like_sql = (["(name LIKE ?)"] * @tokens.size).join(' AND ')

        entry_count = 0
        if (!server_id_list.empty?)
          query = ["#{like_sql} and ftp_server_id in (#{server_id_list.join(',')})", * @tokens.sort]
          entry_count = FtpEntry.count(:conditions => query)
        end

        swap_entry_count = 0
        if (!swap_server_id_list.empty?)
          swap_query = ["#{like_sql} and ftp_server_id in (#{swap_server_id_list.join(',')})", * @tokens.sort]
          swap_entry_count = SwapFtpEntry.count(:conditions => swap_query)
        end

        @entry_count = entry_count + swap_entry_count
        @entry_pages = Paginator.new self, @entry_count, per_page_option, params['page']

        @found_entries = []

        if (entry_count > @entry_pages.current.offset)
          @found_entries += FtpEntry.find(:all,
                                          :limit => @entry_pages.items_per_page,
                                          :offset => @entry_pages.current.offset,
                                          :conditions => query)
        end

        if (swap_entry_count > 0) && (entry_count < @entry_pages.current.last_item)
          @found_entries += SwapFtpEntry.find(:all,
                                              :limit => @entry_pages.items_per_page - @found_entries.size,
                                              :offset => [@entry_pages.current.offset - entry_count, 0].max,
                                              :conditions => swap_query)
        end
      else
        @ftp_question = ""
      end
    end
    @process_time = @process_time

    @ftp_servers = FtpServer.find(:all)
    render :template => 'ezftpsearch/search.html.erb', :layout => !request.xhr?
  end

private
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_params
    if (params[:fq].strip.empty?)
      redirect_to :action => :index, :project_id => @project
    end
  end
end
