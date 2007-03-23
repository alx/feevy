module ManageHelper
  
  # Method to build the Ajax link to display and select an avatar
  def avatar_display(avatar_id, subscription)
    avatar = Avatar.find avatar_id
    # We set the selected classname if avatar correspond to subscription avatar
    if !avatar.nil? && subscription.avatar == avatar then
      link_to_remote(image_tag("#{avatar.url}"),
          {:url => {:action => "select_avatar", 
                    :id => subscription.id, 
                    :avatar_id => avatar.id, 
                    :update_avatar => "#{avatar_id}_#{subscription.id}"}},
          {:id => "#{avatar_id}_#{subscription.id}", :class => "avatar_#{subscription.id} selected_avatar"})
    else
      link_to_remote(image_tag("#{avatar.url}"),
          {:url => {:action => "select_avatar", 
                    :id => subscription.id, 
                    :avatar_id => avatar.id,
                    :update_avatar => "#{avatar_id}_#{subscription.id}"}},
          {:id => "#{avatar_id}_#{subscription.id}", :class => "avatar_#{subscription.id}"})
    end
  end
  
  def select_display_feevy(user)
    user_sub = user.subscriptions.size
    current_option = user.opt_displayed_subscriptions || 0
    selected = ""
    
    # Begin selection form
    result = "<select name='display_feevy' id='display_feevy'>"
    
    # Display all values
    result << option_display_feevy("all",
                                   "all",
                                   current_option == "all")
    
    # List all possible values from n to 1
    user_sub.times do 
      result << option_display_feevy(user_sub, 
                                     "#{user_sub}",
                                     user_sub.to_s == current_option)
      user_sub = user_sub - 1
    end
    
    result << "</select>"
  end
  
  def option_display_feevy(value, string, selected)
    selection = ""
    selection = "SELECTED" if selected == true
    "<option value='#{value}' #{selection}>#{string}</option>"
  end
  
  def select_lang()
    select = "<p>Choose displayed language: 
      <select name='lang' id='lang'>
        <option value='en-EN'>english</option>
        <option value='eo-EO'>esperanto</option>
        <option value='es-AR'>argentinian</option>
        <option value='es-CAT'>catalonian</option>
        <option value='es-EU'>basque euskara</option>
        <option value='fr-FR'>french</option>
        <option value='pt-PT'>portuguese</option>
      </select>"
    select << observe_field("lang",
              :url => {:controller => "manage", :action => "choose_user_lang"},
              :with => "'lang='+ escape($('lang').value)")
    select << "</p>"
    select
  end
  
  def add_blog_box(position='top')
    insert = ""
    result = "
    <div style='display:none;' id='add_blog_box_#{position}' class='cajab'>
      <div class='caja10'>
        <div class='box'>
          <b class='spiffy'>
            <b class='spiffy1'><b></b></b>
            <b class='spiffy2'><b></b></b>
            <b class='spiffy3'></b>
            <b class='spiffy4'></b>
            <b class='spiffy5'></b>
          </b> 
          <div class='spiffy_content'>
            <br/>
            <a class='right' onclick='$(\"add_blog_box_#{position}\").hide()' href='#'>close this box</a>
            <form class='select_blogs' action='/manage/select_blogs' method='post'>
              <div id='add_blog_form_#{position}'>
                <p>blog address<br/><input type='text' name='blogs[]' size='27' id='blogs[]'/></p>
              </div>
              <div class='ladoa'>
                <a onclick='$(\"add_blog_form_#{position}\").innerHTML += \"<p>blog address<br/><input type=text name=blogs[] size=27/></p>\";' href=''>+ add more</a>
                <br/>
              </div>
              <div class='ladob'><input type='submit' class='submit' value='next >' id='boton2'/></div>
              <br/>
              <br/>
            </form>
            <br/>
          </div>
          <b class='spiffy'>
            <b class='spiffy5'></b>
            <b class='spiffy4'></b>
            <b class='spiffy3'></b>
            <b class='spiffy2'><b></b></b>
            <b class='spiffy1'><b></b></b>
          </b>
        </div>
      </div>
    </div>"
  end
end
