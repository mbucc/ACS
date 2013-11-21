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

		var 
			slop = .025  // allow for some error in page heights.
			, b = document.body
			, bodyheight = pagination.height(b)
			;

		// If page fits as is, we're all done.
		if (canvasheight() >= bodyheight * (1.0 - slop))
			return;

		var
			el = null
			, in_blockquote = false
			, canvas_y = canvasheight() * (1.0 - slop)
			, m = pagination.state_machine
			;

		m.init(canvas_y, pagination.IdleState);
		console.log("canvas_y = " + canvas_y);

		do  {
			// Pass null's through.  They mark the end of
			// stream (e.g., inside a blockquote or page).
			el = el ? el.nextSibling : document.body.firstChild;
			m.current_state.process(m, el);
		} while (el);
		b.innerHTML = m.buffer.innerHTML;
	};

	function init() {
		bindReady(bespokifyDOM);
	}

	return {init: init};
})();

acs.init();
