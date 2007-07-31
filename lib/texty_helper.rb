module TextyHelper
  def self.append_features(base) # :nodoc:
    super
    base.extend ClassMethods
  end

  module ClassMethods
    
    def read_encoding(file)
      logger.debug "----read_encoding---"
      logger.debug "----"
      charset = file.charset.gsub("\"", "")
      logger.debug "file charset: #{charset}"

      file.rewind
      file.each { |line|          
        # Fetch charset
        if (line =~ /(<meta)|(<\?xml)/m) and (line =~ /encoding=["'](.[^"']*)/m or line =~ /charset=["'](.[^"']*)/m)
          charset = $1.downcase
          logger.debug "charset found: #{charset}"
        end
      }
      logger.debug charset

      logger.debug "----   ---"
      charset      
    end
    
    def clean(html, length = 45)
      return html if html.blank?
      if html.index("<")
        text = ""
        tokenizer = HTML::Tokenizer.new(html)

        while token = tokenizer.next
          node = HTML::Node.parse(nil, 0, 0, token, false)
          # result is only the content of any Text nodes
          text << node.to_s if node.class == HTML::Text  
        end
        # strip any comments, and if they have a newline at the end (ie. line with
        # only a comment) strip that too
        truncate(text.gsub(/<!--(.*?)-->[\n]?/m, ""), length)
      else
        truncate(html, length) # already plain text
      end 
    end

    def truncate(text, length = 45, truncate_string = "...")
      if text.nil? then
         return
      end
      l = length - truncate_string.length
      if text.length > length 
        text = text[0...l]
        # Avoid html entity truncation
        if text =~ /(&#\d+[^;])$/
          text.delete!($1)
        end
        text = text + truncate_string
      end
      text
    end

    def convertEncoding(text, encoding='utf-8')
      
      # Set encoding if nil
      encoding = 'utf-8' if encoding.blank?
      logger.debug "Encoding: #{encoding}"
      
      # Pre-process encoding
      unless text.nil?
        if encoding == 'utf-8'
          # Some strange caracters to handle
          text.gsub!("\342\200\042", "&ndash;")   # en-dash
          text.gsub!("\342\200\041", "&mdash;")   # em-dash
          text.gsub!("\342\200\174", "&hellip;")  # elipse
          text.gsub!("\342\200\176", "&lsquo;")   # single quote
          text.gsub!("\342\200\177", "&rsquo;")   # single quote
          text.gsub!("\342\200\230", "&rsquo;")   # single quote
          text.gsub!("\342\200\231", "&rsquo;")   # single quote
          text.gsub!("\342\200\234", "&ldquo;")   # Double quote, right
          text.gsub!("\342\200\235", "&rdquo;")   # Double quote, left
          text.gsub!("\342\200\242", ".")
          text.gsub!("\342\202\254", "&euro;");   # Euro symbol
          text.gsub!(/\S\200\S/, " ")             # every strange character send to the moon
          text.gsub!("\176", "\'")  # single quote
          text.gsub!("\177", "\'")  # single quote
          text.gsub!("\205", "-")		# ISO-Latin1 horizontal elipses (0x85)
          text.gsub!("\221", "\'")	# ISO-Latin1 left single-quote
          text.gsub!("\222", "\'")	# ISO-Latin1 right single-quote
          text.gsub!("\223", "\"")	# ISO-Latin1 left double-quote
          text.gsub!("\224", "\"")	# ISO-Latin1 right double-quote
          text.gsub!("\225", "\*")	# ISO-Latin1 bullet
          text.gsub!("\226", "-")		# ISO-Latin1 en-dash (0x96)
          text.gsub!("\227", "-")		# ISO-Latin1 em-dash (0x97)
          text.gsub!("\230", "\'")  # single quote
          text.gsub!("\231", "\'")  # single quote
          text.gsub!("\233", ">")		# ISO-Latin1 single right angle quote
          text.gsub!("\234", "\"")  # Double quote
          text.gsub!("\235", "\"")  # Double quote
          text.gsub!("\240", " ")		# ISO-Latin1 nonbreaking space
          text.gsub!("\246", "\|")	# ISO-Latin1 broken vertical bar
          text.gsub!("\255", "")	  # ISO-Latin1 soft hyphen (0xAD)
          text.gsub!("\264", "\'")	# ISO-Latin1 spacing acute
          text.gsub!("\267", "\*")	# ISO-Latin1 middle dot (0xB7)
          ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
          text = ic.iconv(text + ' ')[0..-2]
        elsif encoding == 'iso-8859-15'
          text.gsub!("&#8217;", "'") # Long horizontal bar
        end
      end
      logger.debug "Before conversion: #{text}"

      begin
        conversion = Iconv.new('iso-8859-1', encoding).iconv(text)
        text = conversion
        # Post-process encoding
        unless text.nil? or text.blank? or text.kind_of? ArgumentError
          text.gsub!(/[\240-\377]/) { |c| "&#%d;" % c[0] }
          if encoding == 'iso-8859-15'
            text.gsub!("&#8217;", "'")
          end
        end
      rescue  => err
        logger.debug "problem while converting: #{err}"
        text = ""
      end
      logger.debug "After conversion: #{text}"
      
      text
    end
  end
end