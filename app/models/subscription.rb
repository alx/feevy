class Subscription < ActiveRecord::Base
  acts_as_taggable
  
  belongs_to :user
  belongs_to :feed
  belongs_to :avatar
  
  def Subscription.create_default
    subscription = Subscription.new
    subscription.update_attribute :avatar_id, Avatar.find(1).id
    subscription
  end
  
  def feevy_avatar_url
    self.avatar.url
  end
end
