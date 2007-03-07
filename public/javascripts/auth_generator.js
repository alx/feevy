/*
 * This is used with The account facility
 *
 * Fabien Penso <penso@linuxfr.org>
 */

function load_page() {
	 if (document.getElementById('post_login')) {
     if (document.getElementById('post_login').value == '') {
       document.getElementById('post_login').focus();
     } else if (document.getElementById('post_password'))  {
       document.getElementById('post_password').focus();
     }
	 } else if(document.getElementById('post_email')) {
		 document.getElementById('post_email').focus();
	 }
}

/**
 * Prevent load_page from breaking other onload events
**/
if (typeof Behavior != 'undefined') {
  Behavior.addLoadEvent(load_page);
} else {
  if (typeof addLoadEvent != 'function') {
    function addLoadEvent(func) {
      var old_onload = window.onload;
      if (typeof window.onload != 'function') {
	    window.onload = func;
	  } else {
	    window.onload = function() { old_onload; func; }
	  }
    }
  }
  addLoadEvent(load_page);
}
