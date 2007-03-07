require 'erb'

[RAILS_DEFAULT_LOGGER, ActiveRecord::Base.logger].each do |logger|
	logger.class.class_eval do 
		def dump_to_buf(lvl,str)
			self.send("unhooked_#{lvl}".to_sym, str)
			if $browser_buf
				$browser_buf << [lvl,str]
			end
		end
	end
	singleton = class << logger; self; end;
	for level in [:info, :debug, :trace, :warn, :error] do
		singleton.send(:public)
		unless logger.respond_to? "unhooked_#{level}".to_sym
  		singleton.send(:alias_method, "unhooked_#{level}".to_sym, level.to_sym) rescue nil
		end
		singleton.class_eval <<-EOS
 	 	 	 def #{level}(msg = nil)
		      msg = yield if msg == nil && block_given?
		      self.dump_to_buf("#{level}", msg) 
	   	 end
	  EOS
	end
end

module ActionController
 class Base
 	 alias_method(:unhooked_process,:process) unless self.respond_to? :unhooked_process_method
	 def process(request,response, method = :perform_action, *arguments)
		 $browser_buf ||= [] if request.params.key?('logs!') or request.params.key?('log!')
		 unhooked_process(request,response, method, *arguments)   
	 end
 end
 class CgiResponse
 	 alias_method :unhooked_out, :out
	 def out(output = $stdout)
		 if $browser_buf
			 body.gsub!(/<\/body>.*$/mi,'')
			 body << ERB.new(File.open(File.join(File.dirname(__FILE__), '..', 'templates','log.rhtml'), 'r').read).result
			 body << '</body></html>'
			 $browser_buf = nil
		 end
		 unhooked_out(output)
	 end
 end
end
