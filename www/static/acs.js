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

		var header_el = getHeader("h2");

		var
			el = document.body.firstElementChild
			, eltmp
			, canvas_y = canvasheight() * (1.0 - slop)
			, y = 0
			, page_y = 0
			, page_i = 0
			, in_blockquote = false
			;

		console.log("canvas_y = " + canvas_y);

		m = state_machine(page_height_px);
		el = document.body.firstChild;
		while (el) {
			m.state.process(el);
			el = el.nextSibling;
		}
		//this.body.innerHtml = m.state.body.innerHtml;

		/*
		while (el) {
			// Blockquotes can be really long (e.g., the entire
			// news item appears in a block quote), so we want to
			// break inside blockquote.
			if (el.nodeName.toUpperCase() == "BLOCKQUOTE") {
				console.log("** entering BLOCKQUOTE");
				el = el.firstElementChild;
				in_blockquote = true;
			}
			y = el.getBoundingClientRect().height + topmargin(el);
			if (need_pagebreak(el, page_y, canvas_y)) {
				console.log("    break @ " + page_y);
				console.log("-------------------------");
				if (page_fits(
					y
					, canvas_y
					, header_el
					, page_i
					))
				{
					page_y = 0;
				}
				else
					alert("XXX: stub.");
			}
			page_y = page_y + y;
			console.log(y + ":" + el.nodeName);
			eltmp = el.nextElementSibling;
			if (eltmp) {
				el = eltmp;
			}
			else {
				if (in_blockquote) {
					console.log("** exiting BLOCKQUOTE");
					el = el
						.parentElement
						.nextElementSibling;
					in_blockquote = false;
				}
				else {
					el = eltmp;
				}
			}
		}
		if (page_y > 0) {
			console.log("    end last @ = " + page_y);
			console.log("-------------------------");
		}
		*/
	};

	function init() {
		bindReady(bespokifyDOM);
	}

	return {init: init};
})();

acs.init();
