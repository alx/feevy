ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"


  # ruta por defecto
  map.connect '', :controller => 'welcome', :action => 'welcome'
  map.connect 'terms', :controller => 'welcome', :action => 'terms'
  map.connect 'faq', :controller => 'welcome', :action => 'faq'
  map.connect 'privacy', :controller => 'welcome', :action => 'privacy'
  
  map.auth 'auth/:action/:id',
    :controller => 'auth', :action => nil, :id => nil
  map.authadmin 'authadmin/:action/:id',
    :controller => 'authadmin', :action => nil, :id => nil
  map.authadmin 'admin/:action/:id',
    :controller => 'admin', :action => nil, :id => nil
  
  map.connect '/code/:id/tag/:tags/rss.xml',                :controller => 'feevy', :action => 'rss'
  map.connect '/code/:id/tags/:tags/rss.xml',               :controller => 'feevy', :action => 'rss'
  map.connect '/code/:id/rss.xml',                          :controller => 'feevy', :action => 'rss'
  
  map.connect '/code/:id/tag/:tags/style/:style',   :controller => 'feevy', :action => 'show'
  map.connect '/code/:id/tag/:tags/:style',         :controller => 'feevy', :action => 'show'
  map.connect '/code/:id/tag/:tags',                :controller => 'feevy', :action => 'show'
  map.connect '/code/:id/tags/:tags/style/:style',  :controller => 'feevy', :action => 'show'
  map.connect '/code/:id/tags/:tags/:style',        :controller => 'feevy', :action => 'show'
  map.connect '/code/:id/tags/:tags',               :controller => 'feevy', :action => 'show'
  map.connect '/code/:id/:style',                   :controller => 'feevy', :action => 'show'
  map.connect '/code/:id',                          :controller => 'feevy', :action => 'show'
  
  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end