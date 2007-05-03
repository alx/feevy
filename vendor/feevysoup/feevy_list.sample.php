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
dev api_key: ce2827565b9410316713848c32dd354355efb2ba<br /><br />


<form method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
<input type="hidden" name="action" value="add_feed" />
<input type="hidden" name="api_key" value="ce2827565b9410316713848c32dd354355efb2ba" />
Blog url:<input type="text" name="url" value="" id="url">
<input type="submit" value="Add Feed" />
</form>

<form method="post" action="<?php echo $_SERVER['PHP_SELF']; ?>">
<input type="hidden" name="action" value="list_feed" />
<input type="hidden" name="api_key" value="ce2827565b9410316713848c32dd354355efb2ba" />
<input type="submit" value="Get Feed List" />
</form>




<?php


	if(!empty($_POST['action'])) {

		include "feevySoup.php";

		$api = new feevySoup;	// create a new object

		$api->api_key = $_POST['api_key'];	// your API key
    
		$api->type = $_POST['action'];	// what API method to call?

		switch($_POST['action']) {
			case 'add_feed':
			  $api->params = array('url' => $_POST['url']);
			break;
		}

		$content = $api->get_content();	// get the content

    if(isset($content['error'])){
      echo "<p style=\"color:red;\">{$content['error']}</p>";
    }

		// Go through the array and print the contents
		foreach($content['result']['feed'] as $feed) {
		  echo "<img src=\"{$feed['avatar']}\" width=40 height=40 align=middle/><strong>Feed #{$feed['id']}</strong><br />\n";
  		echo "<ul>\n";
  		echo "<li>name: {$feed['name']}</li>\n";
  		echo "<li>url: <a href=\"{$feed['url']}\">{$feed['url']}</a></li>\n";
  		echo "<li>tags: {$feed['tags']}</li>\n";
  		echo "</ul>\n";
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