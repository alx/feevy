# :stopdoc:
require 'htree/modules'
require 'htree/fstr'

module HTree # :nodoc:
  module Node # :nodoc:
    # raw_string returns a source string recorded by parsing.
    # It returns +nil+ if the node is constructed not via parsing.
    def raw_string
      catch(:raw_string_tag) {
        return raw_string_internal('')
      }
      nil
    end
  end

  class Doc # :nodoc:
    def raw_string_internal(result)
      @children.each {|n|
        n.raw_string_internal(result)
      }
    end
  end

  class Elem # :nodoc:
    def raw_string_internal(result)
      @stag.raw_string_internal(result)
      @children.each {|n| n.raw_string_internal(result) }
      @etag.raw_string_internal(result) if @etag
    end
  end

  module Tag # :nodoc:
    def init_raw_string() @raw_string = nil end
    def raw_string=(arg) @raw_string = HTree.frozen_string(arg) end
    def raw_string_internal(result)
      throw :raw_string_tag if !@raw_string
      result << @raw_string
    end
  end

  module Leaf # :nodoc:
    def init_raw_string() @raw_string = nil end
    def raw_string=(arg) @raw_string = HTree.frozen_string(arg) end
    def raw_string_internal(result)
      throw :raw_string_tag if !@raw_string
      result << @raw_string
    end
  end

  class Text # :nodoc:
    def raw_string=(arg)
      if arg == @rcdata then
        @raw_string = @rcdata
      else
        super
      end
    end
  end

  module Node # :nodoc:
    def eliminate_raw_string
      raise NotImplementedError
    end
  end

  class Doc # :nodoc:
    def eliminate_raw_string
      Doc.new(@children.map {|c| c.eliminate_raw_string })
    end
  end

  class Elem # :nodoc:
    def eliminate_raw_string
      Elem.new!(
        @stag.eliminate_raw_string,
        @empty ? nil : @children.map {|c| c.eliminate_raw_string },
        @etag && @etag.eliminate_raw_string)
    end
  end

  class Text # :nodoc:
    def eliminate_raw_string
      Text.new_internal(@rcdata)
    end
  end

  class STag # :nodoc:
    def eliminate_raw_string
      STag.new(@qualified_name, @attributes, @inherited_context)
    end
  end

  class ETag # :nodoc:
    def eliminate_raw_string
      self.class.new(@qualified_name)
    end
  end

  class XMLDecl # :nodoc:
    def eliminate_raw_string
      XMLDecl.new(@version, @encoding, @standalone)
    end
  end

  class DocType # :nodoc:
    def eliminate_raw_string
      DocType.new(@root_element_name, @public_identifier, @system_identifier)
    end
  end

  class ProcIns # :nodoc:
    def eliminate_raw_string
      ProcIns.new(@target, @content)
    end
  end

  class Comment # :nodoc:
    def eliminate_raw_string
      Comment.new(@content)
    end
  end
end
# :startdoc:
