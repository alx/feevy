class Avatar < ActiveRecord::Base
  has_many :subscription
  has_many :feed

  # Return default avatars
  def Avatar.commons
    return Avatar.find(1,2,3,4,5,6,7,8)
  end

  def is_common?
    return (1..8)===self.id
  end

  def Avatar.create_from_file(file, format)
    unless file.nil?
      require 'gd2'

      avatar = Avatar.create

      saved_file = "images/avatars/#{avatar.id}." << format
      filepath = "#{RAILS_ROOT}/public/#{saved_file}"
      avatar_url = "http://www.feevy.com/#{saved_file}"
      saved = false

      logger.debug "#{saved_file}"
      logger.debug "#{filepath}"
      logger.debug "#{avatar_url}"
      
      begin
        File::open(file.path, mode="r") { |f|
          img = nil
          img = GD2::Image.load(f)

          if not img.nil?
            nHeight = nWidth = 40
            if img.height != 40 or img.width != 40
              aspect_ratio = img.width.to_f / img.height.to_f
              if aspect_ratio > 1.0
                nWidth  = 40 * aspect_ratio
              else
                nHeight = 40 / aspect_ratio
              end                
            end  
            thumb = GD2::Image::TrueColor.new(40, 40)
            thumb.copy_from(img, 0,0,0,0,nWidth, nHeight, img.width, img.height)
            
            thumb.export(filepath)
            saved = true
          end
        }  
      rescue => err
        logger.error "error: #{err}"
      end

      if saved == true
        avatar.update_attributes :url => avatar_url
        return avatar
      else
        avatar.destroy
        return nil
      end
    end
    return nil
  end
end
