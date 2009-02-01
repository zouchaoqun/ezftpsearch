require 'redmine'

Redmine::Plugin.register :redmine_ezftpsearch do
  name 'Redmine ezFtpSearch plugin'
  author 'Zou Chaoqun'
  description 'This is a ftp search plugin for Redmine with a ftp spider'
  version '0.0.1'

  project_module :ezftpsearch do
    permission :view_ezftpsearch, {:ezftpsearch => [:index, :search]}, :require => :member
    permission :manage_ftpservers, {:ftpservers => [:index, :new, :edit, :destroy]}, :require => :member
  end

  menu :project_menu, :ezftpsearch, {:controller => 'ezftpsearch', :action => 'index'}, :caption => :label_ezftpsearch, :param => :project_id
end
