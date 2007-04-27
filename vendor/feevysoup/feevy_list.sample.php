<html>
<head><title>FeevySoup List API demo</title>

<style type="text/css">
<!--

	html,body {
		font-family: Verdana;
		font-size: 12px;
	}

	.keyword {
		color: #4AAB1A;
	}

	#main {
		width: 500px;
		margin: 30px;
	}

	a {
		color: #3366FF;
	}

	a small {
		color: #5B605D;
	}

//-->
</style>

</head>
<body>
<div id="main">
<h1>FeevySoup (Feed List api)</h1>
<br />

<form method="get" action="<?php echo $_SERVER['PHP_SELF']; ?>">
<input type="text" name="query" /> <input type="submit" value="Search" />
</form>




<?php


	if(!empty($_REQUEST['query'])) {

		include "feevySoup.php";

		$api = new feevySoup;	// create a new object

		$api->api_key = "dfe71294d89ebbca982c98ecd73c96d5";	// your API key

		$api->type = 'list_feeds';	// what API method to call?

		$api->params = array('limit' => 3);	// the parameters

		$content=$api->get_content();	// get the content

print_r($content); exit;


		echo "<strong>{$content['result']['querycount']}</strong> results found<br /><br />\n";

		// Go through the array and print the contents
		foreach($content['item'] as $item) {
			echo "<a href=\"{$item['permalink']}\"><strong>{$item['title']}</strong></a><br />\n";
			echo  html_entity_decode($item['excerpt'])."<br />\n";
			echo "<small>Posted on {$item['created']} in</small> <a href=\"{$item['weblog']['url']}\"><strong><small>{$item['weblog']['name']}</small></strong></a><br /><br /><br />\n";
		}
	}


?>




<br /><br /><br />
--------------------------------
<br />
<small>Duck Soup API library by</small> <a href="http://kailashnadh.name/ducksoup"><small>Kailash Nadh</small></a>
</div>
</body>
</html>