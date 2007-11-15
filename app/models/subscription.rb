class Subscription < ActiveRecord::Base
  acts_as_taggable
  
  belongs_to :user
  belongs_to :feed
  belongs_to :avatar
  
  def feevy_avatar_url
    self.avatar.url
  end
  
  def remove_duplicates
    nb_duplicates = 0
    subscriptions = Subscription.find(:all)
    subscriptions.each do |subscription|
       duplicates = subs.select{|duplicate| duplicate.id != subscription.id 
                                            and duplicate.user_id == subscription.user_id 
                                            and duplicate.feed_id == subscription.feed_id}
       duplicates.each do |duplicate|
         logger.debug "Duplicate found: #{duplicate.id}"
         nb_duplicates += 1
         #duplicate.destroy
         subscriptions.delete(duplicate)
       end
       subscriptions.delete(subscription)
    end
    logger.info "Duplicates found: #{nb_duplicates}"
  end
end
