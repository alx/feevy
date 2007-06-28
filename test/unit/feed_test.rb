require File.dirname(__FILE__) + '/../test_helper'

class FeedTest < Test::Unit::TestCase
  fixtures :feeds, :subscriptions

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end
  
  def test_create_feed_from_becker
    feed = test_creation "http://www.becker-posner-blog.com/index.rdf"
  end
  
  def test_create_feed_from_slashdot
    test_creation("http://www.slashdot.com", "http://rss.slashdot.org/Slashdot/slashdot")
  end
  
  def test_create_feed_from_planeta_lamatriz
    test_creation("http://planeta.lamatriz.org", "http://planeta.lamatriz.org/feed/")
  end
  
  def test_create_feed_from_blogger
    test_creation("http://lorebetta.blogspot.com/", "http://www.lorenabetta.info/feed/")
  end
  
  def test_create_feed_from_wordpress
    test_creation("http://www.deugarte.com/", "http://www.deugarte.com/feed/")
  end
  
  def test_create_feed_with_utf8_problems
    test_creation "http://organizandolaesperanza.blogspot.com"
    test_creation "http://rss.jumpcut.com/rss/user?u_id=DB9EC418FDAF11DB8198000423CEF5F6"
    test_creation "http://bitacora.feevy.com"
  end
  
  def test_create_feed_with_description_problems
    test_creation "http://skblackburn.blogspot.com/"
  end
  
  def test_create_feed_from_ianasagasti
    feed = test_creation "http://ianasagasti.blogs.com/"
    assert_not_nil feed.latest_post
    assert_equal "EL LEHENDAKARI HABLA CLARO", feed.latest_post.title
  end
  
  def test_create_feed_from_pablomancini
    feed = test_creation "http://nadapersonal.blogspot.com"
  end
  
  def test_create_feed_from_elpais
    feed = test_creation "http://lacomunidad.elpais.com/krismontesinos/"
    feed = test_creation "http://lacomunidad.elpais.com/krismontesinos/posts"
    feed = test_creation "http://lacomunidad.elpais.com/krismontesinos"
  end
  
  def test_create_feed_with_ecoperiodico
    test_creation "http://www.ecoperiodico.com/"
  end
  
  def test_create_feed_with_jumpcut
    test_creation "http://www.jumpcut.com/myhome/?u_id=DB9EC418FDAF11DB8198000423CEF5F6"
  end
  
  def test_create_feed_with_rss
    test_creation "http://rss.jumpcut.com/rss/user?u_id=DB9EC418FDAF11DB8198000423CEF5F6"
  end
  
  def test_create_feed_from_minijoan
    feed = test_creation "http://minijoan.vox.com/"
  end
  
  def test_create_feed_from_sombra
    feed = test_creation "http://sombra.lamatriz.org/"
    assert_not_nil feed.latest_post
    assert_equal "Basura y Energía", feed.latest_post.title
  end
  
  def test_performance_on_deugarte
    feed = test_creation "http://www.deugarte.com/"
    60.times {feed.refresh}
  end
  
  def test_create_feed_from_spaces
    feed = test_creation "http://tristezza0.spaces.live.com/", "http://tristezza0.spaces.live.com/feed.rss"
    assert_equal "CHE NE PENSATE ???", feed.title
  end
  
  def test_create_feed_from_lacoctelera
    test_creation "http://lacoctelera.com/macadamia"
  end
  
  def test_create_feed_from_diariodeunadislexica
    test_creation "http://diariodeunadislexica.blogspot.com/"
  end
  
  def test_create_feed_from_liberation
    feed = test_creation "http://www.liberation.fr"
    assert_equal "Lib&#233;ration - Bienvenue", feed.title
  end
  
  def test_create_feed_from_blogspot_with_rss
    feed = test_creation "http://diputadodelosverdes.blogspot.com/", "http://diputadodelosverdes.blogspot.com/feeds/posts/default?alt=rss"
  end
  
  def test_create_with_duranarquitectos
    feed = Feed.find 125
    feed.refresh
  end
  
  def test_create_feed_from_svn_37signals
    feed = test_creation "http://svn.37signals.com/", "http://feeds.feedburner.com/37signals/beMH"
  end
  
  def test_title_encoding_with_cinclin
    feed = Feed.create_from_blog("http://cinclin.blogspot.com/")
    assert_equal "Nom&#233;s 5 l&#237;nies", feed.title
  end
  
  def test_encoding_esperanto
    text = "Historio de Esperanto, Aleksander Korĵenkov"
    encoded_text = Feed.convertEncoding text
    puts encoded_text
  end
  
  def test_create_feed_from_takingitglobal
    feed = Feed.create_from_blog "http://www.takingitglobal.org/connections/tigblogs/feed.rss?UserID=251"
  end

  def test_create_feed_from_rubendomfer
    feed = Feed.create_from_blog "http://www.rubendomfer.com/blog/"
  end
  
  def test_encoding_on_claudiaramos
    feed = Feed.create_from_blog("http://claudiaramos.blogspot.com/")
  end
  
  def test_encoding_on_arfues
    feed = Feed.create_from_blog("http://www.arfues.net/weblog/")
  end
  
  def test_encoding_on_lkstro
    feed = Feed.create_from_blog("http://www.lkstro.com/")
  end
  
  def test_encoding_on_lorenabetta
    feed = Feed.create_from_blog("http://www.lorenabetta.info")
  end
  
  def test_encoding_on_adesalambrar
     feed = Feed.create_from_blog("http://www.adesalambrar.info/")
  end
  
  def test_encoding_on_dreams
     feed = Feed.create_from_blog("http://dreams.draxus.org/")
  end
  
  def test_encoding_sobrerailes
    feed = test_creation("http://mephisto.sobrerailes.com/")
  end
  
  def test_bogus_link_without_href
    feed = test_creation("http://blog.zvents.com/", "http://blog.zvents.com/feed/atom.xml")
  end
  
  def test_create_duplicate_feeds
    feed_size = Feed.count
    Feed.create_from_blog("http://www.slashdot.com")
    Feed.create_from_blog("http://slashdot.com")
    assert_equal feed_size + 1, Feed.count
  end
  
  def test_discover_avatat_nil
    feed = Feed.create_from_blog("http://www.slashdot.com")
    assert_nil feed.discover_avatar_txt
  end
  
  def test_discover_avatar
    avatar_size = Avatar.count
    feed = Feed.create_from_blog("http://www.lkstro.com")
    assert_not_nil feed.avatar
    assert_not_nil feed.avatar.url
    assert_equal avatar_size + 1, Avatar.count
  end
  
  def test_discover_404
    avatar_size = Avatar.count
    feed = Feed.create_from_blog("http://www.lacoctelera.com/macadamia/")
    assert_nil feed.avatar
    assert_equal avatar_size, Avatar.count
  end
  
  def test_merge_duplicates
    central_feed = Feed.find 124
    merged_feed = Feed.find 125
    
    feed_count = Feed.count
    sub_count = Subscription.count
    central_feed_sub_count = central_feed.subscriptions.size
    
    Feed.merge_duplicates(central_feed.id, merged_feed.id)
    assert_equal feed_count - 1, Feed.count
    assert_equal sub_count, Subscription.count
    assert_equal central_feed_sub_count + 1, central_feed.subscriptions.size
  end
  
  private
    def test_creation(url, link="")
      feed_size = Feed.count
      feed = Feed.create_from_blog(url)
      assert_equal feed_size + 1, Feed.count
      if link != ""
        assert_equal link, feed.link
      end
      feed
    end
end
