<?php
/*
Plugin Name: Feevy Ping
Plugin URI: http://www.feevy.com
Description: Ping Feevy when you publish a new post
Author: Las Indias - Alexandre Girard
Version: 1.0
Author URI: http://feevy.com
*/

// This gets called at the publish_post action
function ping_feevy() {
	$url  = "http://localhost:3000/ping/update";
	$data = "url=".urlencode(get_feed_link('rss2'));
	
	$params = array('http' => array(
		'method' => 'POST',
		'content' => $data
		));

	$ctx = stream_context_create($params);
	$fp = @fopen($url, 'rb', false, $ctx);
	if (!$fp) {
		throw new Exception("Problem with $url, $php_errormsg");
	}
}

// Add action hook for post publishing
add_action('publish_post', 'ping_feevy')

?>