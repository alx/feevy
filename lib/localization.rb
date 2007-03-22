module Localization
  mattr_accessor :lang

  @@l10s = { :default => {} }
  @@lang = :default

  def self._(string_to_localize, *args)
    translated = 
      @@l10s[@@lang][string_to_localize] || string_to_localize
    return translated.call(*args).to_s if translated.is_a? Proc
    translated = 
      translated[args[0]>1 ? 1 : 0] if translated.is_a?(Array)
    sprintf translated, *args
  end

  def self.define(lang = :default)
    @@l10s[lang] ||= {}
    yield @@l10s[lang]
  end

  def self.load
    Dir.glob("#{RAILS_ROOT}/lang/*.rb"){ |t| require t }
    Dir.glob("#{RAILS_ROOT}/lang/custom/*.rb"){ |t| require t }
  end

end