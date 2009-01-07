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

  layout 'base'
  before_filter :find_project, :authorize

  def index
    @ftp_servers = FtpServer.find(:all)
  end

  def search
    server_id_list = Array.new
    swap_server_id_list = Array.new

    servers = FtpServer.find(:all)
    for server in servers
      if (params[server.id.to_s] == "1")
        if (server.in_swap)
          swap_server_id_list.insert(-1, server.id)
        else
          server_id_list.insert(-1, server.id)
        end
      end
    end

    if (!server_id_list.empty?)
      @found_entries = FtpEntry.find(:all,
        :conditions => "name like '%#{params[:q]}%' and ftp_server_id in (#{server_id_list.join(',')})")
    end

    if (!swap_server_id_list.empty?)
      @found_entries2 = SwapFtpEntry.find(:all,
        :conditions => "name like '%#{params[:q]}%' and ftp_server_id in (#{swap_server_id_list.join(',')})")
    end
    
  end

private
  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
