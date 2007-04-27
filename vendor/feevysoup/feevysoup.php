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

			// These routine prepares the query for each API type
			switch($this->type) {

				// ============== Cosmos api
				case 'cosmos':

						// == Prepare the parameters for the cosmos api
						$cosmos['url']=(!isset($this->params['url'])) ? '' : "&url=".$this->params['url'];
						$cosmos['type']=(!isset($this->params['type'])) ? '' :"&type=".$this->params['type'];
						$cosmos['limit']=(!isset($this->params['limit'])) ? '' : "&limit=".$this->params['limit'];
						$cosmos['start']=(!isset($this->params['start'])) ? '' : "&start=".$this->params['start'];
						$cosmos['current']=(!isset($this->params['current'])) ? '' : "&current=".$this->params['current'];
						//$cosmos['format']=(!isset($this->params['format'])) ? '' : "&format=".$this->params['format'];
						$cosmos['claim']=(!isset($this->params['claim'])) ? '' : "&claim=".$this->params['claim'];
						$cosmos['highlight']=(!isset($this->params['highlight'])) ? '' : "&highlight=".$this->params['highlight'];

						// == Prepare the url for cosmos api query
						$query="/cosmos?key={$this->api_key}{$cosmos['url']}";
						$url.="{$cosmos['type']}{$cosmos['limit']}{$cosmos['start']}";
						$url.="{$cosmos['current']}{$cosmos['claim']}{$cosmos['highlight']}";
				break;


				// ============== Search api
				case 'search':

						// == Prepare the parameters for the search api
						$search['query']=(!isset($this->params['query'])) ? '' : "&query=".$this->params['query'];
						$search['start']=(!isset($this->params['start'])) ? '' : "&start=".$this->params['start'];
						$search['limit']=(!isset($this->params['limit'])) ? '' : "&limit=".$this->params['limit'];
						//$search['format']=(!isset($this->params['format'])) ? '' : "&format=".$this->params['format'];
						$search['claim']=(!isset($this->params['claim'])) ? '' : "&claim=".$this->params['claim'];
						$search['language']=(!isset($this->params['language'])) ? '' : "&claim=".$this->params['language'];
						$search['authority']=(!isset($this->params['authority'])) ? '' : "&authority=".$this->params['authority'];

						// == Prepare the url for search api query
						$query="/search?key={$this->api_key}{$search['query']}";
						$query.="{$search['limit']}{$search['start']}{$search['claim']}{$search['language']}{$search['authority']}";
				break;


				// ============== getinfo api
				case 'getinfo':

						// == Prepare the parameters for the getinfo api
						$getinfo['username']=(!isset($this->params['username'])) ? '' : "&username=".$this->params['username'];
						//$getinfo['format']=(!isset($this->params['format'])) ? '' : "&format=".$this->params['format'];

						// == Prepare the url for getinfo api query
						$query="/getinfo?key={$this->api_key}{$getinfo['username']}";
				break;


				// ============== outbound api
				case 'outbound':

						// == Prepare the parameters for the getinfo api
						$outbound['url']=(!isset($this->params['url'])) ? '' : "&url=".$this->params['url'];
						//$outbound['format']=(!isset($this->params['format'])) ? '' : "&format=".$this->params['format'];
						$outbound['start']=(!isset($this->params['start'])) ? '' : "&start=".$this->params['start'];

						// == Prepare the url for getinfo api query
						$query="/outbound?key={$this->api_key}{$outbound['url']}{$outbound['start']}";
				break;


				// ============== bloginfo api
				case 'bloginfo':

						// == Prepare the parameters for the getinfo api
						$bloginfo['url']=(!isset($this->params['url'])) ? '' : "&url=".$this->params['url'];
						//$bloginfo['format']=(!isset($this->params['format'])) ? '' : "&format=".$this->params['format'];

						// == Prepare the url for getinfo api query
						$query="/bloginfo?key={$this->api_key}{$bloginfo['url']}";
				break;


				// ============== taginfo api
				case 'taginfo':

						// == Prepare the parameters for the getinfo api
						$taginfo['tag']=(!isset($this->params['tag'])) ? '' : "&tag=".$this->params['tag'];
						$taginfo['limit']=(!isset($this->params['limit'])) ? '' : "&limit=".$this->params['limit'];
						$taginfo['start']=(!isset($this->params['start'])) ? '' : "&start=".$this->params['start'];
						//$taginfo['format']=(!isset($this->params['format'])) ? '' : "&format=".$this->params['format'];
						$taginfo['excerptsize']=(!isset($this->params['excerptsize'])) ? '' : "&excerptsize=".$this->params['excerptsize'];
						$taginfo['topexcerptsize']=(!isset($this->params['topexcerptsize'])) ? '' : "&topexcerptsize=".$this->params['topexcerptsize'];

						// == Prepare the url for getinfo api query
						$query="/tag?key={$this->api_key}{$taginfo['tag']}{$taginfo['limit']}";
						$query.="{$taginfo['start']}{$taginfo['excerptsize']}{$taginfo['topexcerptsize']}";
				break;


				// ============== toptags api
				case 'toptags':
						// == Prepare the url for getinfo api query
						$toptags['limit']=(!isset($this->params['limit'])) ? '' : "&limit=".$this->params['limit'];
						$query="/toptags?key={$this->api_key}{$toptags['limit']}";
				break;


				// ============== keyinfo api
				case 'keyinfo':
						// == Prepare the url for getinfo api query
						$query="/keyinfo?key={$this->api_key}";
				break;

				// ============== blogPostTags api
				case 'blogposttags':
						$blogposttags['url']=(!isset($this->params['url'])) ? '' : "&url=".$this->params['url'];
						$blogposttags['limit']=(!isset($this->params['limit'])) ? '' : "&limit=".$this->params['limit'];

						// == Prepare the url for blogPostTags api query
						$query="/blogposttags?key={$this->api_key}{$blogposttags['url']}{$blogposttags['limit']}";
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