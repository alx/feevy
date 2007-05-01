<?php

//	error_reporting(error_reporting() & ~E_STRICT);
	// helps run on php5. e_strict doesnt do any good anyway ;)

/* =========================================

	FeevySoup v1.0 (Feevy API library)
	April 27 2007
	
	Developed by
		Gorka Julio
		teketen@gmail.com, teketen.com
		
		Alexandre Girard
		alx.girard@gmail.com, alexgirard.com
		
	Inspired by
	  DuckSoup (c) 2005-2006, Kailash Nadh (http://kailashnadh.name)

	Feevy website
		http://www.feevy.com

	Documentation
		http://www.feevy.com/api/

  ========================================= */



class feevySoup {

	var $host = "localhost";  // Feevy API server host (no http:// and no trailing slash)
	var $port = 3000;	        // Feevy API server port

	var $api_key;
	var $type;
	var $params;

  var $path   = "";
	var $query  = "";


	// ============= creates a tree (array) from the given xml data (only for internal use)
	function xml2array($text) {
	   $reg_exp = '/<(\w+)[^>]*>(.*?)<\/\\1>/s';
	   echo "text: $text\n";
	   print_r($text);
	   preg_match_all($reg_exp, $text, $match);
		   foreach ($match[1] as $key=>$val) {
	       if ( preg_match($reg_exp, $match[2][$key]) ) {
    	       $array[$val][] = $this->xml2array($match[2][$key]);
	       } else {
    	       $array[$val] = $match[2][$key];
	       }
	   }
	   return $array;
	}


	// ============= Prepares the query based on the given api/parameters
	function prepare_query() {

		// == No API type has been specified
		if(!$this->type) {
			return false;
		}

		// urlencode the parameters
		if(isset($this->params) && is_array($this->params)) {
			while(list($key, $value) = each($this->params)) {
				$this->params[$key]=urlencode($value);
			}
		}

			// These routine prepares the query for each API call
			switch($this->type) {
			  
				// ============== register_user api call
				case 'register_user':
				break;

				// ============== verify_key api call
				case 'verify_key':
						// == Prepare the url for verify_key api query
						$path   = "/api/verify_key";
						$query  = "key={$this->api_key}";
				break;
				
				// ============== view_key api call
				case 'view_key':
						$view_key['email']=(!isset($this->params['email'])) ? '' : "&email=".$this->params['email'];
						$view_key['password']=(!isset($this->params['password'])) ? '' : "&password=".$this->params['password'];
						// == Prepare the url for view_key api query
						$path   = "/api/view_key";
						$query  = "key={$this->api_key}{$view_key['email']}{$view_key['password']}";
				break;
				
				// ============== list_feed api call
				case 'list_feed':
						// == Prepare the url for list_feed api query
						$path   = "/api/list_feed";
						$query  = "key={$this->api_key}";
				break;
        
				// ============== add_feed api call
				case 'add_feed':
				  $add_feed['url']=(!isset($this->params['url'])) ? '' : "&url=".$this->params['url'];
				  // == Prepare the url for add_feed api query
					$path   = "/api/add_feed";
				  $query  = "key={$this->api_key}{$add_feed['url']}";
				break;
				
				// ============== delete_feeds api call
				case 'delete_feeds':
				  $delete_feeds['feeds_id']=(!isset($this->params['feeds_id'])) ? '' : "&feeds_id=".$this->params['feeds_id'];
				  // == Prepare the url for delete_feeds api query
					$path   = "/api/delete_feeds";
				  $query  = "key={$this->api_key}{$delete_feeds['feeds_id']}";
				break;
				
				// ============== edit_tags api call
				case 'edit_tags':
				  $edit_tags['feed_id']=(!isset($this->params['feed_id'])) ? '' : "&feed_id=".$this->params['feed_id'];
  				$edit_tags['tag_list']=(!isset($this->params['tag_list'])) ? '' : "&tag_list=".$this->params['tag_list'];
				  // == Prepare the url for edit_tags api query
					$path   = "/api/edit_tags";
				  $query  = "key={$this->api_key}{$edit_tags['feed_id']}{$edit_tags['tag_list']}";
				break;
				
				// ============== edit_avatar api call
				case 'edit_avatar':
				  $edit_avatar['feed_id']=(!isset($this->params['feed_id'])) ? '' : "&feed_id=".$this->params['feed_id'];
  				$edit_avatar['avatar_url']=(!isset($this->params['avatar_url'])) ? '' : "&avatar_url=".$this->params['avatar_url'];
				  // == Prepare the url for edit_avatar api query
					$path   = "/api/edit_avatar";
				  $query  = "key={$this->api_key}{$edit_avatar['feed_id']}{$edit_avatar['avatar_url']}";
				break;
				
				// ============== No proper type ?
				default:
					return false;
				break;

			}

		$this->query=$query;
		$this->path=$path;
		print "\nQuery: [$query]\n\n";

	}


	// ============= Fetches the data over http from Feevy
	function fetch_content() {
    
		// =========== Fetch the data
		$data="";
		
  	$http_request  = "POST {$this->path} HTTP/1.0\r\n";
  	$http_request .= "Host: {$this->host}\r\n";
  	$http_request .= "Content-Type: application/x-www-form-urlencoded; charset=UTF-8\r\n";
  	$http_request .= "Content-Length: " . strlen($this->query) . "\r\n";
  	$http_request .= "User-Agent: Feevy Soup\r\n";
  	$http_request .= "\r\n";
  	$http_request .= $this->query;
    
  	if( false != ( $fs = @fsockopen($this->host, $this->port, $errno, $errstr, 10) ) ) {
  		fwrite($fs, $http_request);

  		while ( !feof($fs) )
  			$data .= fgets($fs, 1160); // One TCP-IP packet
  		fclose($fs);
  		$data = explode("\r\n\r\n", $data, 2);
  	}
  	
  	return $data;
  }
  



	// ============= The core function that processes Feevy data
	function get_content() {

		// == No API type has been specified
		if(!$this->type) {
			return false;
		}

		$this->prepare_query();	// Prepare the query with all necessary variables
		$data=$this->fetch_content();	// get data from Feevy
		
		if(!$data) return false;

		$xml_array=$this->xml2array($data);
		if(!$xml_array) return false;
		print_r($xml_array);
		//$parent=$xml_array['tapi'][0]['document']['0'];

			// parses and formats data for each API
			switch($this->type) {
			  
				// ============== register_user api call
				case 'register_user':
					$result['result']=$parent['result'][0];

					if(!isset($result['error'])) {
						$result['result']['weblog']=$result['result']['weblog'][0];
					}
				break;

				// ============== verify_key api call
				case 'verify_key':
					$result['result']=$parent['result'][0];

					if(!isset($result['error'])) {
						$result['result']['weblog']=$result['result']['weblog'][0];
					}
				break;
				
				// ============== view_key api call
				case 'view_key':
					$result['result']=$parent['result'][0];

					if(!isset($result['error'])) {
						$result['result']['weblog']=$result['result']['weblog'][0];
					}
				break;
				
				// ============== list_feed api call
				case 'list_feed':
					$result['result']=$parent['result'][0];

					if(!isset($result['error'])) {
						$result['result']['weblog']=$result['result']['weblog'][0];
					}
				break;
        
				// ============== add_feed api call
				case 'add_feed':
					$result['result']=$parent['result'][0];

					if(!isset($result['error'])) {
						$result['result']['weblog']=$result['result']['weblog'][0];
					}
				break;
				
				// ============== delete_feeds api call
				case 'delete_feeds':
					$result['result']=$parent['result'][0];

					if(!isset($result['error'])) {
						$result['result']['weblog']=$result['result']['weblog'][0];
					}
				break;
				
				// ============== edit_tags api call
				case 'edit_tags':
					$result['result']=$parent['result'][0];

					if(!isset($result['error'])) {
						$result['result']['weblog']=$result['result']['weblog'][0];
					}
				break;
				
				// ============== edit_avatar api call
				case 'edit_avatar':
					$result['result']=$parent['result'][0];

					if(!isset($result['error'])) {
						$result['result']['weblog']=$result['result']['weblog'][0];
					}
				break;
				
				// ============= format the cosmos data
				case 'cosmos':
					$cosmos_result=$parent['result'][0];

					if(!isset($cosmos_result['error'])) {
						// === the base weblog
						$cosmos_result['weblog']=$cosmos_result['weblog'][0];

						// ==== Author data if present (when claim=1)
						if(isset($cosmos_result['weblog']['author']) && is_array($cosmos_result['weblog']['author'])) {
							$cosmos_result['weblog']['author']=$cosmos_result['weblog']['author'][0];
						}

						$result['result']=$cosmos_result;

						// === linked weblogs
						if(isset($parent['item']) && is_array($parent['item'])) {
							$n=0;
							foreach($parent['item'] as $item) {
								$item['weblog']=$item['weblog'][0];
								$result['item'][$n]['weblog']=$item['weblog'][0];

								// ==== Author data if present (when claim=1)		
								if(isset($item['weblog']['author']) && is_array($item['weblog']['author'])) {
									$item['weblog']['author']=$item['weblog']['author'][0];
								}

								$result['item'][$n]=$item;
								$n++;
							}
						}
					}
				break;
			}

		return $result;
	}

}

?>