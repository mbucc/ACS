/*
 * Javascript routines for the Arsdigita Community System.
 * Created on Sun Nov 10 08:32:57 EST 2013 by Mark Bucciarelli <mkbucc@gmail.com>
 */

"use strict";

var acs = {
	// From http://stackoverflow.com/questions/3437786.
	canvassize: function() {
		var 	w = window
		    	, d = document
			, e = d.documentElement
			, g = d.getElementsByTagName('body')[0]
			, x = w.innerWidth || e.clientWidth || g.clientWidth
			, y = w.innerHeight|| e.clientHeight|| g.clientHeight
			;
		return {x: x, y: y};
	}

	// Return the value of the style for the given element.
	// For example,
	//
	// 	> acs.getStyle(document.body, "margin-top")
	// 	"20px"
	//
	, getStyle: function(element, style) {
		var y = null;
		if (element.currentStyle)
			y = element.currentStyle[style];
		else if (window.getComputedStyle)
			y = document
				.defaultView
				.getComputedStyle(element, null)
				.getPropertyValue(style);
		return y;
	}

	// "20px" --> 20
	// "20"   --> 20
	// "20em" --> 0
	// "20%"  --> 0
	, pxtoi: function(val) {
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
	}

        // How many pixels will given HTML require when rendered?  Counts
	// everything except the margin.  Example (in browser console):
	//
	//     > acs.markupsize(document.body.innerHTML)
	//     Object {x: 463, y: 547}
	//
	, markupsize: function(html) {
		var
			div = document.createElement('div')
			, x = 0
			, y = 0
			, b = document.body
			, bodyVerticalMargins = Math.max(
				16
				, this.pxtoi(this.getStyle(b, "margin-top"))
					+ this.pxtoi(this.getStyle(b, "margin-bottom"))
				)
			;
		div.setAttribute('class', 'textDimensionCalculation');
		div.innerHTML = html;

		document.body.appendChild(div);

		// Returns the height of the visible area for an
		// object, in pixels. The value contains the height
		// with the padding, scrollBar, and the border, but
		// does not include the margin.
		// ref: http://help.dottoro.com/ljuxqbfx.php
		x = div.offsetWidth;
		y = div.offsetHeight + bodyVerticalMargins;

		//div.parentNode.removeChild(div);

		return {x:x, y:y};
	}
};
