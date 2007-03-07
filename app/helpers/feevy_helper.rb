module FeevyHelper
  # limitamos el texto de una entrada a 
  def abbreviate(text, limit)
    unless text.size > limit
      strip_html(text)[0..limit] + '(...)'
    else
      strip_html(text)[0..limit] 
    end
  end
  
  def strip_html(line) 
      line.gsub(/\n/, ' ').gsub(/<.*?>/, '') 
  end
  
  def safe_truncate(text, limit, truncate_string = "...")
  end
  
  def url_escape(string)
    "');document.write(unescape('" << string.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
    end << "'));document.write('"
  end
end
