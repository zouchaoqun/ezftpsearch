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

class FtpserversController < ApplicationController
  unloadable
  
  layout 'base'
  menu_item :ezftpsearch, :only => [:index, :new, :edit, :destroy]
  
  before_filter :find_project, :authorize
  verify :method => :post, :only => :destroy

  def index
    @servers = FtpServer.find(:all)
  end

  def new
    @server = FtpServer.new(params[:ftpserver])
    if request.get?
      @server.port = 21
      @server.ftp_type = 'Unix'
      @server.ftp_encoding = 'ISO-8859-1'
      @server.force_utf8 = false
      @server.ignored_dirs = '. .. .svn'
    elsif request.post?
      @server.in_swap = true
      if @server.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :controller => 'ftpservers', :action => 'index', :project_id => @project
      end
    end
  end

  def edit
    @server = FtpServer.find(:first, :conditions => "id = #{params[:server_id]}")
    if request.post? and @server.update_attributes(params[:ftpserver])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :controller => 'ftpservers', :action => 'index', :project_id => @project
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def destroy
    @server = FtpServer.find(:first, :conditions => "id = #{params[:server_id]}")
    @server.destroy
    redirect_to :controller => 'ftpservers', :action => 'index', :project_id => @project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
  
private
  def find_project   
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
