<?php
/*
Plugin Name: feevy widget
Description: Adds a sidebar widget to display your feevy bar
Author: Las Indias - Alexandre Girard
Version: 1.0
Author URI: http://feevy.com
*/

// This gets called at the plugins_loaded action
function widget_feevy_init() {
	
	// Check for the required API functions
	if ( !function_exists('register_sidebar_widget') || !function_exists('register_widget_control') )
		return;

	// This saves options and prints the widget's config form.
	function widget_feevy_control() {
		$options = $newoptions = get_option('widget_feevy');
		if ( $_POST['feevy-submit'] ) {
			$newoptions['title'] = strip_tags(stripslashes($_POST['feevy-title']));
			$newoptions['code'] = strip_tags(stripslashes($_POST['feevy-code']));
			$newoptions['tags'] = explode(' ', trim(strip_tags(stripslashes($_POST['feevy-tags']))));
			$newoptions['style'] = strip_tags(stripslashes($_POST['feevy-style']));
		}
		if ( $options != $newoptions ) {
			$options = $newoptions;
			update_option('widget_feevy', $options);
		}
	?>
				<div style="text-align:right">
				<label for="feevy-title" style="line-height:35px;display:block;"><?php _e('Widget title:', 'widgets'); ?> <input type="text" id="feevy-title" name="feevy-title" value="<?php echo wp_specialchars($options['title'], true); ?>" /></label>
				<label for="feevy-code" style="line-height:35px;display:block;"><?php _e('Your feevy ID:', 'widgets'); ?> <input type="text" id="feevy-code" name="feevy-code" value="<?php echo $options['code']; ?>" /></label>
				<label for="feevy-tags" style="line-height:35px;display:block;"><?php _e('Select your feevy style:', 'widgets'); ?>
				<select name="feevy-style" id="feevy-style">
					<option value="dark" <?php if ($options['code'] == "dark") echo "SELECTED"; ?>>dark</option>
					<option value="white" <?php if ($options['code'] == "white") echo "SELECTED"; ?>>white</option>
					<option value="liquid" <?php if ($options['code'] == "liquid") echo "SELECTED"; ?>>liquid</option>
				</select></label>
				<label for="feevy-tags" style="line-height:35px;display:block;"><?php _e('Show only these tags (separated by spaces):', 'widgets'); ?> <textarea id="feevy-tags" name="feevy-tags" style="width:290px;height:20px;"><?php echo wp_specialchars(implode(' ', (array) $options['tags']), true); ?></textarea></label>
				<input type="hidden" name="feevy-submit" id="feevy-submit" value="1" />
				</div>
	<?php
	}

	// This prints the widget
	function widget_feevy($args) {
		extract($args);
		# Load blog.feevy.com code with white skin by default
		$defaults = array('code' => 18, 'style' => 'white');
		$options = (array) get_option('widget_feevy');

		foreach ( $defaults as $key => $value )
			if ( !isset($options[$key]) )
				$options[$key] = $defaults[$key];

		$feevy_url = 'http://www.feevy.com/code/' . $options['code'];
		$feevy_url.= (count($options['tags']) and (count($options['tags'][0]) > 1)) ? '/tags/' . implode('+', $options['tags']) : '';
		$feevy_url.= '/' . $options['style'];
		?>
		<?php echo $before_widget; ?>
			<?php echo $before_title . "{$options['title']}" . $after_title; ?><div id="feevy-box" style="margin:0;padding:0;border:none;"> </div>
			<script type="text/javascript" src="<?php echo $feevy_url; ?>"></script>
		<?php echo $after_widget; ?>
<?php
	}

	// Tell Dynamic Sidebar about our new widget and its control
	register_sidebar_widget(array('Feevy', 'widgets'), 'widget_feevy');
	register_widget_control(array('Feevy', 'widgets'), 'widget_feevy_control');
	
}

// Delay plugin execution to ensure Dynamic Sidebar has a chance to load first
add_action('widgets_init', 'widget_feevy_init');

?>