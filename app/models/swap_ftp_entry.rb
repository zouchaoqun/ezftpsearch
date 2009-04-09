class SwapFtpEntry < ActiveRecord::Base
  belongs_to :ftp_server
  acts_as_tree :order => 'name'

  def full_path
    if parent
      p = ancestors.reverse.join('/')
      '/' + p + '/'
    else
      '/'
    end
  end

  def to_s
    name
  end

  def type
    if directory
      l(:text_type_directory)
    else
      l(:text_type_file)
    end
  end

end
