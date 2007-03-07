require File.dirname(__FILE__) + '/../test_helper'

class AvatarTest < Test::Unit::TestCase
  fixtures :avatars

  def test_upload_avatar
    
  end
  
  def test_fetch_avatar_txt
    
  end
  
  def test_set_feed_avatar
    
  end
  
  def test_create_from_file
    require 'tempfile'
    
    avatar_file = File.new("/tmp/dummy.png")
    
    nb_avatars = Avatar.count
    
    tempfile = Tempfile.new("tmp")
    tempfile.write avatar_file.read
    tempfile.flush
    
    Avatar.create_from_file tempfile, "png"
    
    assert_equal nb_avatars + 1, Avatar.count
  end
end
