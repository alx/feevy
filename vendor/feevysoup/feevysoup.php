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

	var $api_fqdn="www.feevy.com/api/";	// Feevy API server (no http:// and no trailing slash)

	var $api_key;
	var $type;
	var $params;

	var $query = "";


	// ============= creates a tree (array) from the given xml data (only for internal use)
	function xml2array($text) {
	   $reg_exp = '/<(\w+)[^>]*>(.*?)<\/\\1>/s';
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
						$query="/verify_key?key={$this->api_key}";
				break;
				
				// ============== view_key api call
				case 'view_key':
						$view_key['email']=(!isset($this->params['email'])) ? '' : "&email=".$this->params['email'];
						$view_key['password']=(!isset($this->params['password'])) ? '' : "&password=".$this->params['password'];
						// == Prepare the url for view_key api query
						$query="/view_key?key={$this->api_key}{$view_key['email']}{$view_key['password']}";
				break;
				
				// ============== list_feeds api call
				case 'list_feeds':
						// == Prepare the url for list_feeds api query
						$query="/blogposttags?key={$this->api_key}{$list_feeds['limit']}";
				break;
        
				// ============== add_feed api call
				case 'add_feed':
				  $add_feed['url']=(!isset($this->params['url'])) ? '' : "&url=".$this->params['url'];
				  // == Prepare the url for add_feed api query
				  $query="/add_feed?key={$this->api_key}{$add_feed['url']}";
				break;
				
				// ============== delete_feeds api call
				case 'delete_feeds':
				  $delete_feeds['feeds_id']=(!isset($this->params['feeds_id'])) ? '' : "&feeds_id=".$this->params['feeds_id'];
				  // == Prepare the url for delete_feeds api query
				  $query="/delete_feeds?key={$this->api_key}{$delete_feeds['feeds_id']}";
				break;
				
				// ============== edit_tags api call
				case 'edit_tags':
				  $edit_tags['feed_id']=(!isset($this->params['feed_id'])) ? '' : "&feed_id=".$this->params['feed_id'];
  				$edit_tags['tag_list']=(!isset($this->params['tag_list'])) ? '' : "&tag_list=".$this->params['tag_list'];
				  // == Prepare the url for edit_tags api query
				  $query="/edit_tags?key={$this->api_key}{$edit_tags['feed_id']}{$edit_tags['tag_list']}";
				break;
				
				// ============== edit_avatar api call
				case 'edit_avatar':
				  $edit_avatar['feed_id']=(!isset($this->params['feed_id'])) ? '' : "&feed_id=".$this->params['feed_id'];
  				$edit_avatar['avatar_url']=(!isset($this->params['avatar_url'])) ? '' : "&avatar_url=".$this->params['avatar_url'];
				  // == Prepare the url for edit_avatar api query
				  $query="/edit_avatar?key={$this->api_key}{$edit_avatar['feed_id']}{$edit_avatar['avatar_url']}";
				break;
				
				// ============== No proper type ?
				default:
					return false;
				break;

			}

		$this->query=$query;
		print "\nQuery: [$query]\n\n";

	}


	// ============= Fetches the data over http from Feevy
	function fetch_content() {

			// =========== Fetch the data
			$data="";


			// Get data by opening a socket connection. If this doesnt work, uncomment and use the routine below
			$fp = @fsockopen($this->api_fqdn, 80, $errnum, $errstr, 15); // Open a socket connection
				if($fp) { 
					$fp_data="GET {$this->query} HTTP/1.0\r\n";
					$fp_data.="Host: {$this->api_fqdn}\r\n"; 
					$fp_data.="User-Agent: FeevySoup client\r\n";
					$fp_data.="Connection: Close\r\n\r\n";
					fputs($fp, $fp_data);
						while(!feof($fp)) {
							$data.=fgets($fp, 512);
						}

					fclose($fp);
				} else {
					return false;
				}

			// Clean up the data by removing the http headers
			$data=substr($data, strpos($data, "\r\n\r\n"), strlen($data));

			/* =============================
			$url="http://".$this->api_fqdn.$this->query;
			$fp=@fopen($url, "r");
			if($fp) {
				while(!feof($fp)) {
					$data.=fgets($fp, 512);
				}
				fclose($fp);
			} else {
				return false;	// connection failed
			}
			================================ */

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

		$parent=$xml_array['tapi'][0]['document']['0'];



			// parses and formats data for each API
			switch($this->type) {

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

				// ============= format search data
				case 'search':
					$result['result']=$parent['result'][0];

					if(!isset($result['error'])  && isset($parent['item']) && is_array($parent['item'])) {
						$n=0;
						foreach($parent['item'] as $item) {
							$item['weblog']=$item['weblog'][0];
							$result['item'][$n]['weblog']=$item['weblog']; //$result['item'][$n]['weblog']=$item['weblog'][0];

							// === Author data if present (when claim=1)
							if(isset($item['weblog']['author']) && is_array($item['weblog']['author'])) {
								$item['weblog']['author']=$item['weblog']['author'][0];
							}

							$result['item'][$n]=$item;

							$n++;
						}
					}
				break;

				// ============= format getinfo data
				case 'getinfo':
					$result['result']=$parent['result'][0];

					if(!isset($result['error']) && isset($result['item']) && is_array($result['item'])) {
						$n=0;
						foreach($parent['item'] as $item) {
							$item['weblog']=$item['weblog'][0];
							$result['item'][$n]['weblog']=$item['weblog'][0];
							$result['item'][$n]=$item;
							$n++;
						}
					}
				break;

				// ============= format outbound data
				case 'outbound':
					$outbound_result=$parent['result'][0];

					if(!isset($result['error'])) {
						$outbound_result['weblog']=$outbound_result['weblog'][0];
						$result['result']=$outbound_result;

						if(isset($parent['item']) && is_array($parent['item'])) {
							$n=0;
							foreach($parent['item'] as $item) {
								$item['weblog']=$item['weblog'][0];
								$result['item'][$n]['weblog']=$item['weblog'][0];
								$result['item'][$n]=$item;
								$n++;
							}
						}
					}
				break;

				// ============= format bloginfo data
				case 'bloginfo':
					$result['result']=$parent['result'][0];

					if(!isset($result['error'])) {
						$result['result']['weblog']=$result['result']['weblog'][0];
					}
				break;

				// ============= format taginfo data
				case 'taginfo':
					$result['result']=$parent['result'][0];

					if(!isset($result['error']) && isset($parent['item']) && is_array($parent['item'])) {
						$n=0;
						foreach($parent['item'] as $item) {
							$item['weblog']=$item['weblog'][0];
							$result['item'][$n]['weblog']=$item['weblog'][0];
							$result['item'][$n]=$item;
							$n++;
						}
					}
				break;

				// ============= format toptags data
				case 'toptags':
					$result['result']=$parent['result'][0];

					if(!isset($result['error']) && isset($parent['item']) && is_array($parent['item'])) {
						$n=0;
						foreach($parent['item'] as $item) {
							$result['item'][$n]=$item;
							$n++;
						}
					}
				break;

				// ============= the keyinfo data
				case 'keyinfo':
					$result['result']=$parent['result'][0];
				break;

				// ============= the blogposttags data
				case 'blogposttags':
				$result['result']=$parent['result'][0];
					if(!isset($result['error']) && isset($parent['item']) && is_array($parent['item'])) {
						$n=0;
						foreach($parent['item'] as $item) {
							$result['item'][$n]=$item;
							$n++;
						}
					}
				break;

			}

		return $result;
	}

}

?>