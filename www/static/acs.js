/*
 * Javascript routines for the Arsdigita Community System.
 * Created on Sun Nov 10 08:32:57 EST 2013
 * by Mark Bucciarelli <mkbucc@gmail.com>
 */

"use strict";

var acs = (function() {

	// DOM ready means the document is created.  (Images may
	// still be downloading.) This cross-browser version is from:
	// http://javascript.info/tutorial/onload-ondomcontentloaded
	function bindReady(handler) {

		var called = false

		function ready() {
			if (called) return
			called = true
			handler()
		}

		if ( document.addEventListener ) { // native event
			document
				.addEventListener(
					"DOMContentLoaded"
					, ready
					, false
					);
		} else if ( document.attachEvent ) {  // IE

			try {
				var isFrame = window.frameElement != null
			} catch(e) {}

			// IE, the document is not inside a frame
			if ( document.documentElement.doScroll && !isFrame )
				tryScroll(called, ready);

			// IE, the document is inside a frame
			document.attachEvent("onreadystatechange", function(){
				if ( document.readyState === "complete" ) {
					ready()
				}
			})
		}

		// Old browsers
		if (window.addEventListener)
			window.addEventListener('load', ready, false)
		else if (window.attachEvent)
			window.attachEvent('onload', ready)
		else {
			// very old browser, copy old onload
			var fn = window.onload
			window.onload = function() {
				// replace by new onload and call the old one
				fn && fn()
				ready()
			}
		}
	}
	
	function init() {
		bindReady(paginate);
	}

	return {init: init};
})();

acs.init();
