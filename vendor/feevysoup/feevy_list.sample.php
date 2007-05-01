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
dev api_key: ce2827565b9410316713848c32dd354355efb2ba<br />
<form method="get" action="<?php echo $_SERVER['PHP_SELF']; ?>">
<input type="submit" value="Get Feed List" />
</form>




<?php


	if(!empty($_REQUEST['api_key'])) {

		include "feevySoup.php";

		$api = new feevySoup;	// create a new object

		$api->api_key = "ce2827565b9410316713848c32dd354355efb2ba";	// your API key

		$api->type = 'list_feed';	// what API method to call?

		$api->params = array();	// the parameters

		$content=$api->get_content();	// get the content

    print_r($content); exit;

		echo "<strong>{$content['result']['querycount']}</strong> results found<br /><br />\n";

		// Go through the array and print the contents
		foreach($content['feed'] as $feed) {
			echo "<a href=\"{$feed['url']}\"><strong>{$item['name']}</strong></a><br />\n";
		}
	}


?>




<br /><br /><br />
--------------------------------
<br />
<small>FeevySoup API library</a>
</div>
</body>
</html>