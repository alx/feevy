require 'test/unit'
require 'autodiscovery'
require 'autodiscovery/helpers/autodiscovery_helper'

class AutodiscoveryTest < Test::Unit::TestCase
  include Autodiscovery::AutodiscoveryHelper

  def setup
    Autodiscovery.reset_configurations

    Autodiscovery::configurations[:technorati_api_key] = "f0af6e8d049f4f3acd5fdc7356ff8a5d"
    Autodiscovery::configurations[:flickr_api_key] = "b17db89ea144a46278ea1351b340eed5"

    Autodiscovery::AutodiscoveryHelper.default_local_path =
    File.expand_path(
    File.expand_path(File.dirname(__FILE__)) + '/../pages')
  end

   def test_load
     with_page(:from_url => 'http://www.slashdot.org') { |page|
       assert_not_nil page.href
     }
   
     with_page(:from_url => 'http://hronia.blogalia.com') { |page|
       assert_not_nil page.href
     }
   
     with_page(:from_url => 'http://beatrizia.lacoctelera.com') { |page|
       assert_not_nil page.href
     }
   
     with_page(:from_url => 'http://www.deugarte.com') { |page|
       assert_not_nil page.href
     }
   
     with_page(:from_url => 'http://www.escolar.net') { |page|
       assert_not_nil page.href
     }
   
     with_page(:from_url => 'http://www.estresados.com') { |page|
       assert_not_nil page.href
     }
   
     with_page(:from_url => 'http://www.thinkvitamin.com') { |page|
       assert_not_nil page.href
     }
   
     with_page(:from_url => 'http://www.minid.net') { |page|
       assert_not_nil page.href
     }
   end
   
   
   def test_technorati_avatar
     with_page(:from_url => 'http://www.enriquedans.com') { |page|
       assert_not_nil page.href
     }
   end
   
   def test_foaf_link
   
     # La Coctelera
     with_page(:from_file => 'macadamia.html') { |page|
       assert_equal(page.foaf_link, 'http://www.lacoctelera.com/macadamia/feeds/foaf01')
     }
   
     # Vox.com
     with_page(:from_file => 'thedailyscott.html') { |page|
       assert_equal(page.foaf_link, 'http://scott.vox.com/profile/foaf.rdf')
     }
   
     # LiveJournal (ojo no todos)
     with_page(:from_file => 'barmaidblog.html') { |page|
       assert_equal(page.foaf_link, 'http://barmaidblog.livejournal.com/data/foaf')
     }
   
     # Typepad (ojo no todos)
     with_page(:from_file => 'thebeav.html') { |page|
       assert_equal(page.foaf_link, 'http://thebeav.blogs.com/foaf.rdf')
     }
   end
   
   def test_blogspot_avatar
     with_page(:from_file => 'lamediahostia.html') { |page| 
       assert_equal(page.get_blogspot_avatar, 'http://es.geocities.com/ivalladt/ismael_bn_195x300.jpg')
     }
   
     with_page(:from_file => 'tyrannosaurus.htm') { |page| 
       assert_equal(page.get_blogspot_avatar, 'http://photos1.blogger.com/blogger/5064/3084/200/avatar_yo01_48x48.jpg')
     }  
   end

   def test_flickr_avatar
     
     with_page(:from_file => 'hronia.htm') { |page| 
       assert_equal(page.get_flickr_avatar, 'http://static.flickr.com/1/buddyicons/30665292@N00.jpg?1102530599')
     }
     
     with_page(:from_url => 'http://lamediahostia.blogspot.com')  { |page|
        assert_equal(page.get_flickr_avatar, 
                    "http://static.flickr.com/13/buddyicons/99365830@N00.jpg?1160719691")
    }
   end

   def test_foaf_avatar
   
     with_page(:from_file => 'macadamia.html') { |page|
       assert_equal(page.get_foaf_avatar, 
         "http://www.lacoctelera.com/myfiles/macadamia/macadamia-ico.gif")
     }
   
     # Vox
     with_page(:from_file => 'yogi.html') { |page| 
       assert_equal(page.get_foaf_avatar, 
         "http://up3.vox.com/6a00c2251c384b8fdb00cd9701ed7e4cd5")
     }
     
   
     # LiveJournal/Typepad
     with_page(:from_file => 'sethgodin.html') { |page|
       assert_equal(page.get_foaf_avatar, 
         'http://sethgodin.typepad.com/head.gif')
     }
   end

  def test_msn_avatar
    with_page(:from_file => 'ronaldinho.html') { |page|
        assert_equal(page.get_msn_avatar, 
          'http://tkfiles.storage.msn.com/x1pnp_rgmi5o51_OL8C7iUAhxDj4j8psMEkpYfJ2JAjQcMY2-twqtM3aWDcGUAO7h0u23fXmB-ET7fVTIH_U8S2fMH90t_4HBdax6ZtOeUzNfU')
      }
  end


end
