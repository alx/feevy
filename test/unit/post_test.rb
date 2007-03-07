require File.dirname(__FILE__) + '/../test_helper'

class PostTest < Test::Unit::TestCase
  fixtures :posts
  
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end
  
  def test_blogspot_not_service
    feed = Feed.create_from_blog "http://nortesur.blogspot.com/"
    assert_equal "http://nortesur.blogspot.com/2006/12/edificio-verde-en-la-prctica.html", feed.latest_post.url
  end

  def test_parse_and_create
    test_link = "test_link"
    test_title = "test_title"
    test_desc = "test_description"
    item = create_new_item test_link, test_title, test_desc
    
    posts_size = Post.count
    post = Post.create_from_item item
    assert_not_nil post
    assert_equal posts_size+1, Post.count
    
    feed = Feed.create :href => "123", :title => "456", :link => "789"
    feed_post_size = feed.posts.size
    feed.posts << post
    assert_equal feed_post_size+1, feed.posts.size
    assert_equal feed.latest_post, post
    assert_equal test_link, feed.latest_post.url
  end
  
  def test_parse_and_modify
    test_link = "test_link"
    test_title = "test_title"
    test_desc = "test_description"
    test_desc_modified = "test_description_modified"
    item = create_new_item test_link, test_title, test_desc
    item_modified = create_new_item test_link, test_title, test_desc_modified
    
    # Create original item
    posts_size = Post.count
    post = Post.create_from_item item
    assert_not_nil post
    assert_equal posts_size+1, Post.count
    
    # Use another item with modified description but same url
    posts_size = Post.count
    modified_post = Post.create_from_item item_modified
    assert_not_nil modified_post
    assert_equal posts_size, Post.count
    assert_equal "test_description_modified", modified_post.description
    assert_equal post.url, modified_post.url
  end
  
  def test_parse_and_same
    test_link = "test_link"
    test_title = "test_title"
    test_desc = "test_description"
    item = create_new_item test_link, test_title, test_desc
    
    # Create original item
    posts_size = Post.count
    post = Post.create_from_item item
    assert_not_nil post
    assert_equal posts_size+1, Post.count
    
    # try to create new post with same item
    posts_size = Post.count
    duplicate_post = Post.create_from_item item
    assert_not_nil duplicate_post
    assert_equal posts_size, Post.count
    assert_equal post.description, duplicate_post.description
    
  end
  
  def create_new_item(link, title, description)
    item = Hash.new
    item[:link] = link
    item[:title] = title
    item[:description] = description
    def item.method_missing(name, *args) self[name] end
    return item
  end
  
  def test_linkify
    text = "blablabla http://www.123.com blablzbla"
    text.gsub!(/([www|http]\S)/ix, '[<a href="\1">link</a>]')
    assert_equal "blablabla [<a href='http://www.123.com'>link</a>] blablzbla", text
    
    text = "blablabla www.123.com blablzbla"
    text.gsub!(/(https?:\/\/(www.)?\S)/, '[<a href="\1">link</a>]')
    assert_equal "blablabla [<a href='www.123.com'>link</a>] blablzbla", text
  end
end
