require 'test/unit'

class StringTests < Test::Unit::TestCase    
  def test_linkify
    text = "blablabla http://www.123.com blablzbla"
    text.gsub!(/((https?:\/\/)?www\.[^\s]*)/, '[<a href=\'\1\'>link</a>]')
    assert_equal "blablabla [<a href='http://www.123.com'>link</a>] blablzbla", text
  
    text = "blablabla www.123.com blablzbla"
    text.gsub!(/((https?:\/\/)?www\.[^\s]*)/, '[<a href=\'\1\'>link</a>]')
    assert_equal "blablabla [<a href='www.123.com'>link</a>] blablzbla", text
  end
end