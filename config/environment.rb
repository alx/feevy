 #Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
#RAILS_GEM_VERSION = '1.1.6'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  #config.frameworks -= [ :action_web_service ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  config.load_paths += %W( #{RAILS_ROOT}/vendor/feedtools-0.2.26/lib )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
  require 'hodel_3000_compliant_logger'
  config.logger = Hodel3000CompliantLogger.new(config.log_path)
end

## configure Globalize plugin with default language
# include Globalize
# # Set default language
# Locale.set_base_language("en-US")
# # eo-EO lang
# Locale.set("eo-EO")
# Locale.set_translation 'read more',               'legu pli'
# Locale.set_translation 'Feevy is a free service', 'Feevy estas senpaga servo'
# Locale.set_translation 'Get yours',               'Obtenu vian'
# # es-BA lang
# Locale.set('eu-BA')
# Locale.set_translation 'read more',               'gehiago irakurri'
# Locale.set_translation 'Feevy is a free service', 'Feevy zerbitzu librea da'
# Locale.set_translation 'Get yours',               'eskuratu zure iturriak'
# # es-CAT lang
# Locale.set('es-CAT')
# Locale.set_translation 'read more',               'llegeix m&eacute;s'
# Locale.set_translation 'Feevy is a free service', 'Feevy &eacute;s un servei gratu&iuml;t'
# Locale.set_translation 'Get yours',               'Aconsegueix el teu'
# # es-AR lang (vos) 
# Locale.set('es-AR')
# Locale.set_translation 'read more',               'Segu&iacute; leyendo'
# Locale.set_translation 'Feevy is a free service', 'Feevy es libre y gratuito'
# Locale.set_translation 'Get yours',               'Hac&eacute; el tuyo'
# # es-UST lang (usted)
# Locale.set('es-UST')
# Locale.set_translation 'read more',               'Siga leyendo'
# Locale.set_translation 'Feevy is a free service', 'Feevy es libre y gratuito'
# Locale.set_translation 'Get yours',               'Haga el tuyo'
# # es-EU lang
# Locale.set('es-EU')
# Locale.set_translation 'read more',               'irakurri gehiago'
# Locale.set_translation 'Feevy is a free service', 'Feevy doan da'
# Locale.set_translation 'Get yours',               'egin zurea'
# # es-AR lang (tu)
# Locale.set('es-ES')
# Locale.set_translation 'read more',               'Sigue leyendo'
# Locale.set_translation 'Feevy is a free service', 'Feevy es libre y gratuito'
# Locale.set_translation 'Get yours',               'Haz el tuyo'
# # es-GAL lang
# #Locale.set('es-GAL')
# #Locale.set_translation 'read more',               'Sigue lendo'
# #Locale.set_translation 'Feevy is a free service', 'Feevy &eacute; un servizo libre e gratuito'
# #Locale.set_translation 'Get yours',               'Fai o teu'
# # fr-FR lang
# Locale.set('fr-FR')
# Locale.set_translation 'read more',               'lire plus'
# Locale.set_translation 'Feevy is a free service', 'Feevy est un service gratuit'
# Locale.set_translation 'Get yours',               'cr&eacute;e le tiens'
# # pt-PT lang
# Locale.set('pt-PT')
# Locale.set_translation 'read more',               'leia mais'
# Locale.set_translation 'Feevy is a free service', 'Feevy &eacute; um serviço livre'
# Locale.set_translation 'Get yours',               'tenha tamb&eacute;m o seu!'

include HTMLEntities

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below
require 'hpricot'
require 'simple-rss'
require 'open-uri'
require 'timeout'
require 'cached_model'
require 'gd2'
require 'rfeedfinder'

# Include your app's configuration here:
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.server_settings = {
  :address  => "mail.feevy.com",
  :port  => 25, 
  :domain  => 'www.feevy.com',
  :user_name => "error+feevy.com",
  :password => "error",
  :authentication => :login
}

FEEVY_URL = "http://www.feevy.com/"
#FeedTools.configurations[:feed_cache] = nil
ActiveRecord::Base.verification_timeout = 14400

memcache_options = {
  :c_threshold => 10_000,
  :compression => true,
  :debug => false,
  :namespace => 'feevy',
  :readonly => false,
  :urlencode => false
}

CACHE = MemCache.new memcache_options
CACHE.servers = 'localhost:11211'