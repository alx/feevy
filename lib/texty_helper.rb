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
          text.gsub!("\342\200\234", "\"") # Double quote, right
          text.gsub!("\342\200\235", "\"") # Double quote, left
          text.gsub!("\342\200\242", ".")
          text.gsub!("\342\202\254", "&euro;"); # Euro symbol
          text.gsub!(/\S\200\S/, " ") # every strange character send to the moon
          text.gsub!("\234", "\"") # Double quote, left
          text.gsub!("\235", "\"") # Double quote, left
          text.gsub!("\223", "-") # Long horizontal bar
        elsif encoding == 'iso-8859-15'
          text.gsub!("&#8217;", "'") # Long horizontal bar
        end
      end
      logger.debug "Before conversion: #{text}"
      
      begin
        text = Iconv.new('iso-8859-1', encoding).iconv(text)
      rescue => err
        @formatted = ""
        err.to_s.unpack('U*').each {|c| @formatted << "\\#{c}"}
        logger.debug "Iconv error: #{err} -- #{@formatted}"
      end
      
      # Post-process encoding
      unless text.nil?
        if encoding == 'utf-8'
          text.gsub!(/[\240-\377]/) { |c| "&#%d;" % c[0] }
        elsif encoding == 'iso-8859-15'
          text.gsub!("&#8217;", "'") # Long horizontal bar
        end
      end
      text
    end
  end
end