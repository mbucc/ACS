/*
 * Javascript routines for the Arsdigita Community System.
 * Created on Sun Nov 10 08:32:57 EST 2013 by Mark Bucciarelli <mkbucc@gmail.com>
 */

"use strict";

var acs = (function() {

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

	// Return the value of the style for the given element.
	// For example,
	//
	// 	> acs.getStyle(document.body, "margin-top")
	// 	"20px"
	//
	function getStyle(element, style) {
		var y = null;
		if (element.currentStyle)
			y = element.currentStyle[style];
		else if (window.getComputedStyle)
			y = document
				.defaultView
				.getComputedStyle(element, null)
				.getPropertyValue(style);
		return y;
	};

	// "20px" --> 20
	// "20"   --> 20
	// "20em" --> 0
	// "20%"  --> 0
	function pxtoi(val) {
		var
			patterns = [
				/^\d+px$/i
				, /^\d+$/
				]
			, rval = 0
			;
		if (val) {
			for (var i = 0; i < patterns.length && rval == 0; i++)
				if (patterns[i].test(val))
					rval = parseInt(val);
		}
		return rval;
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

	// DOM ready means the document is created.  (Images may still be downloading.)
	// This is a cross-browser version from:
	// http://javascript.info/tutorial/onload-ondomcontentloaded
	function bindReady(handler) {

		var called = false

		function ready() {
			if (called) return
			called = true
			handler()
		}

		if ( document.addEventListener ) { // native event
			document.addEventListener( "DOMContentLoaded", ready, false )
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
			var fn = window.onload // very old browser, copy old onload
			window.onload = function() { // replace by new onload and call the old one
				fn && fn()
				ready()
			}
		}
	}

	function dumpheights() {
		var b = document.body;

		console.log("body margin-top   : " + pxtoi(getStyle(b, "margin-top")));
		console.log("body margin-bottom: " + pxtoi(getStyle(b, "margin-bottom")));
		console.log("body              : " + b.getBoundingClientRect().height);
		console.log("header            : " + b.getElementsByTagName('header')[0].getBoundingClientRect().height);
	};

	function init() {
		bindReady(dumpheights);
	}

	return {init: init};
})();

acs.init();
