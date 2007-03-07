require 'rubygems'

spec = Gem::Specification.new do |s|

  #### Basic information.

  s.name = 'Technorati-Ruby'
  s.version = '0.1.0'
  s.summary = <<-EOF
    Technorati(http://technorati.com/) bindings for Ruby.
  EOF
  s.description = <<-EOF
    Technorati (http://technorati.com/) bindings for Ruby.
  EOF

  s.requirements << 'Ruby, version 1.8.0 (or newer)'
  s.requirements << 'REXML (included with Ruby 1.8.x)'
  s.requirements << 'ParseDate (included with Ruby 1.8.x)'

  #### Which files are to be included in this gem?  Everything!  (Except CVS directories.)

  s.files = Dir.glob("**/*").delete_if { |item| item.include?("CVS") }

  #### C code extensions.

  s.require_path = '.' # is this correct?
  # s.extensions << "extconf.rb"

  #### Load-time details: library and application (you will need one or both).
  s.autorequire = 'technorati'
  s.has_rdoc = true
  s.rdoc_options = ['--webcvs',
  'http://cvs.pablotron.org/cgi-bin/viewcvs.cgi/technorati/', '--title',
  'Technorati-Ruby API Documentation', 'technorati.rb', 'README', 'ChangeLog',
  'COPYING', 'examples/referrer_rss.rb']

  #### Author and project details.

  s.author = 'Paul Duncan'
  s.email = 'pabs@pablotron.org'
  s.homepage = 'http://www.pablotron.org/software/technorati-ruby/'
  s.rubyforge_project = 'technorati-ruby'
end
