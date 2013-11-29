/*
 * Javascript routines for the Arsdigita Community System.
 * Created on Sun Nov 10 08:32:57 EST 2013
 * by Mark Bucciarelli <mkbucc@gmail.com>
 */

"use strict";

var acs = (function() {

	function canvasheight() {
		return canvassize().y;
	};


	// From http://stackoverflow.com/questions/3437786.
	function canvassize() {
		var 	w = window
		    	, d = document
			, e = d.documentElement
			, g = d.getElementsByTagName('body')[0]
			, x = w.innerWidth || e.clientWidth || g.clientWidth
			, y = w.innerHeight|| e.clientHeight|| g.clientHeight
			;
		return {x: x, y: y};
	};

	function tryIEScroll(called, ready) {
		if (called) return
		try {
			document.documentElement.doScroll("left")
			ready()
		} catch(e) {
			setTimeout(tryScroll, 10)
		}
	}

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

	function bespokifyDOM() {

		var bodyheight = pagination.height(document.body);

		// If page fits as is, we're all done.
		if (canvasheight() >= bodyheight * (1.0 - slop))
			return;

		var
			el
			, slop = .025  // allow for some error in page heights.
			, canvas_y = canvasheight() * (1.0 - slop)
			, m = pagination.state_machine(canvas_y)
			;

		var loop_i = 0;
		el = document.body.firstChild;
		while (el && loop_i < 5000) {
			loop_i += 1;
			el = m.process(m, el);
		};
		m.finish_page();

		if (el)
			// XXX: send error message back to server.
			alert("Error");

		document.body.innerHTML = m.html();

	};

	function init() {
		bindReady(bespokifyDOM);
	}

	return {init: init};
})();

acs.init();
