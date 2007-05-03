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
	
	var $get_attributes = 0; // Some API call only need to get xml attributes


	// ============= creates a tree (array) from the given xml data
	function xml2array($contents) {

    if(!$contents) return array();

    if(!function_exists('xml_parser_create')) {
        print "'xml_parser_create()' function not found!";
        return array();
    }
    //Get the XML parser of PHP - PHP must have this module for the parser to work
    $parser = xml_parser_create();
    xml_parser_set_option( $parser, XML_OPTION_CASE_FOLDING, 0 );
    xml_parser_set_option( $parser, XML_OPTION_SKIP_WHITE, 1 );
    xml_parse_into_struct( $parser, $contents, $xml_values );
    xml_parser_free( $parser );

    if(!$xml_values) return;//Hmm...

    //Initializations
    $xml_array = array();
    $parents = array();
    $opened_tags = array();
    $arr = array();

    $current = &$xml_array;

    //Go through the tags.
    foreach($xml_values as $data) {
        unset($attributes,$value);//Remove existing values, or there will be trouble
        extract($data);//We could use the array by itself, but this cooler.

        $result = '';
        if($this->get_attributes) {//The second argument of the function decides this.
            $result = array();
            if(isset($value)) $result['value'] = $value;

            //Set the attributes too.
            if(isset($attributes)) {
                foreach($attributes as $attr => $val) {
                    if($this->get_attributes == 1) $result['attr'][$attr] = $val; //Set all the attributes in a array called 'attr'
                }
            }
        } elseif(isset($value)) {
            $result = $value;
        }

        //See tag status and do the needed.
        if($type == "open") {//The starting of the tag '<tag>'
            $parent[$level-1] = &$current;

            if(!is_array($current) or (!in_array($tag, array_keys($current)))) { //Insert New tag
                $current[$tag] = $result;
                $current = &$current[$tag];

            } else { //There was another element with the same tag name
                if(isset($current[$tag][0])) {
                    array_push($current[$tag], $result);
                } else {
                    $current[$tag] = array($current[$tag],$result);
                }
                $last = count($current[$tag]) - 1;
                $current = &$current[$tag][$last];
            }

        } elseif($type == "complete") { //Tags that ends in 1 line '<tag />'
            //See if the key is already taken.
            if(!isset($current[$tag])) { //New Key
                $current[$tag] = $result;

            } else { //If taken, put all things inside a list(array)
                if((is_array($current[$tag]) and $this->get_attributes == 0)//If it is already an array...
                        or (isset($current[$tag][0]) and is_array($current[$tag][0]) and $this->get_attributes == 1)) {
                    array_push($current[$tag],$result); // ...push the new element into that array.
                } else { //If it is not an array...
                    $current[$tag] = array($current[$tag],$result); //...Make it an array using using the existing value and the new value
                }
            }

        } elseif($type == 'close') { //End of tag '</tag>'
            $current = &$parent[$level-1];
        }
    }
    return($xml_array);
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
		
		// do not get attributes by default
		$get_attributes = 0;

			// These routine prepares the query for each API call
			switch($this->type) {
			  
				// ============== register_user api call
				case 'register_user':
						$view_key['email']=(!isset($this->params['email'])) ? '' : "&email=".$this->params['email'];
						$view_key['password']=(!isset($this->params['password'])) ? '' : "&password=".$this->params['password'];
						// == Prepare the url for view_key api query
						$path   = "/api/register_user";
						$query  = "api_key={$this->api_key}{$view_key['email']}{$view_key['password']}";
					  $get_attributes = 1;
				break;

				// ============== verify_key api call
				case 'verify_key':
						// == Prepare the url for verify_key api query
						$path   = "/api/verify_key";
						$query  = "api_key={$this->api_key}";
					  $get_attributes = 1;
				break;
				
				// ============== view_key api call
				case 'view_key':
						$view_key['email']=(!isset($this->params['email'])) ? '' : "&email=".$this->params['email'];
						$view_key['password']=(!isset($this->params['password'])) ? '' : "&password=".$this->params['password'];
						// == Prepare the url for view_key api query
						$path   = "/api/view_key";
						$query  = "api_key={$this->api_key}{$view_key['email']}{$view_key['password']}";
					  $get_attributes = 1;
				break;
				
				// ============== list_feed api call
				case 'list_feed':
						// == Prepare the url for list_feed api query
						$path   = "/api/list_feed";
						$query  = "api_key={$this->api_key}";
				break;
        
				// ============== add_feed api call
				case 'add_feed':
				  $add_feed['url']=(!isset($this->params['url'])) ? '' : "&url=".$this->params['url'];
				  // == Prepare the url for add_feed api query
					$path   = "/api/add_feed";
				  $query  = "api_key={$this->api_key}{$add_feed['url']}";
				break;
				
				// ============== delete_feeds api call
				case 'delete_feeds':
				  $delete_feeds['feeds_id']=(!isset($this->params['feeds_id'])) ? '' : "&feeds_id=".$this->params['feeds_id'];
				  // == Prepare the url for delete_feeds api query
					$path   = "/api/delete_feeds";
				  $query  = "api_key={$this->api_key}{$delete_feeds['feeds_id']}";
				break;
				
				// ============== edit_tags api call
				case 'edit_tags':
				  $edit_tags['feed_id']=(!isset($this->params['feed_id'])) ? '' : "&feed_id=".$this->params['feed_id'];
  				$edit_tags['tag_list']=(!isset($this->params['tag_list'])) ? '' : "&tag_list=".$this->params['tag_list'];
				  // == Prepare the url for edit_tags api query
					$path   = "/api/edit_tags";
				  $query  = "api_key={$this->api_key}{$edit_tags['feed_id']}{$edit_tags['tag_list']}";
				break;
				
				// ============== edit_avatar api call
				case 'edit_avatar':
				  $edit_avatar['feed_id']=(!isset($this->params['feed_id'])) ? '' : "&feed_id=".$this->params['feed_id'];
  				$edit_avatar['avatar_url']=(!isset($this->params['avatar_url'])) ? '' : "&avatar_url=".$this->params['avatar_url'];
				  // == Prepare the url for edit_avatar api query
					$path   = "/api/edit_avatar";
				  $query  = "api_key={$this->api_key}{$edit_avatar['feed_id']}{$edit_avatar['avatar_url']}";
				break;
				
				// ============== No proper type ?
				default:
					return false;
				break;

			}

		$this->query=$query;
		$this->path=$path;
		$this->get_attributes=$get_attributes;
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
  	
  	return $data[1];
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

			// parses and formats data for each API
			switch($this->type) {
			  
				// ============== register_user api call
				case 'register_user':
				  if(isset($xml_array['feevy']) && is_array($xml_array['feevy'])) {
					  $result['result']=$xml_array['feevy'];
				  }else{
				    $result['error'] = "An error occured while registering this user";
				  }
				break;

				// ============== verify_key api call
				case 'verify_key':
				  if(isset($xml_array['feevy']) && is_array($xml_array['feevy'])) {
					  $result['result']=$xml_array['feevy'];
				  }else{
				    $result['error'] = "An error occured while verifying this api key: {$this->api_key}";
				  }
				break;
				
				// ============== view_key api call
				case 'view_key':
				  if(isset($xml_array['feevy']) && is_array($xml_array['feevy'])) {
					  $result['result']=$xml_array['feevy'];
				  }else{
				    $result['error'] = "An error occured while viewing this user api key";
				  }
				break;
				
				// ============== list_feed api call
				case 'list_feed':
				  if(isset($xml_array['feevy']) && is_array($xml_array['feevy'])) {
				    $result['result']=$xml_array['feevy'];
				  }
					else {
					  $result['error'] = "An error occured while retrieving list of feeds with {$this->api_key}";
					}
				break;
        
				// ============== add_feed api call
				case 'add_feed':
				  if(isset($xml_array['feevy']) && is_array($xml_array['feevy'])) {
				    $result['result']=$xml_array['feevy'];
				  }
					else {
					  $result['error'] = "An error occured while adding feed";
					}
				break;
				
				// ============== delete_feeds api call
				case 'delete_feeds':
				  if(isset($xml_array['feevy']) && is_array($xml_array['feevy'])) {
				    $result['result']=$xml_array['feevy'];
				  }
					else {
					  $result['error'] = "An error occured while deleting feeds";
					}
				break;
				
				// ============== edit_tags api call
				case 'edit_tags':
				  if(isset($xml_array['feevy']) && is_array($xml_array['feevy'])) {
				    $result['result']=$xml_array['feevy'];
				  }
					else {
					  $result['error'] = "An error occured while editing tags";
					}
				break;
				
				// ============== edit_avatar api call
				case 'edit_avatar':
				  if(isset($xml_array['feevy']) && is_array($xml_array['feevy'])) {
				    $result['result']=$xml_array['feevy'];
				  }
					else {
					  $result['error'] = "An error occured while editing avatar";
					}
				break;
			}

		return $result;
	}

}

?>