class Subscription < ActiveRecord::Base
  acts_as_taggable
  
  belongs_to :user
  belongs_to :feed
  belongs_to :avatar
  
  def feevy_avatar_url
    self.avatar.url
  end
end
