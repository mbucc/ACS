// State Machine that handles pagination.
// Created on Thu Nov 14 20:05:35 EST 2013
// by Mark Bucciarelli <mkbucc@gmail.com>
"use strict";


var paginate = (function () {

	// Return true if the element is a heading.
	function is_heading(el) {
		return el && /H[1-6]/.test(el.nodeName);
	};

	// Return true if the element is a header tag.
	function is_header(el) {
		return el && el.nodeName == "HEADER";
	};

	function is_break(el) {
		return el && el.nodeName == "BR";
	};

	function is_blockquote(el) {
		return el && el.nodeName == "BLOCKQUOTE";
	};

	// Returns the first heading element inside the <header> section.
	function getHeader(elname) {

		var headers = document.body.getElementsByTagName('header');

		if (!headers)
			return null;

		for (var el = headers[0].firstChild; el; el = el.nextSibling)
			if (is_heading(el))
				return el;

		return null;
	};

	// Return size of browser window in pixels.
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

	function canvasheight() {
		return canvassize().y;
	};


	// Insert element as first child in parent.
	function insert(parent_el, el) {
		parent_el.insertBefore(el, parent_el.firstChild);
	}

	// Page is overfull.  Split last element added.
	function trim_page(buffer, page, canvas_px) {

		var el = page.lastChild;

		insert(buffer, el);

		// Always move headings to the next page.
		if (is_heading(el))
			return;

		if (is_blockquote(el)) {
			var bq = document.createElement('blockquote');
			page.appendChild(bq);
			add_until_full(page, bq, el, canvas_px);
			insert(el, bq.lastChild);
			return;
		}

		insert(buffer, el);

	};

	function add_until_full(page, parent_el, buf, canvas_px) {
		for (
				var el = buf.firstChild;
				el && page.offsetHeight < canvas_px;
				el = buf.firstChild
				)
			parent_el.appendChild(el);
	}


	function _paginate() {

		var
			  b = document.body
			, canvas_px = canvasheight()
			, page_n = 0
			, buffer = document.createElement('div')
			, page = null
			;


		// When you move an element from one parent to another, it is
		// automatically removed from the previous parent, and what
		// was it's sibling is now promoted to first child.
		for (var el = b.firstChild; el; el = b.firstChild)
			buffer.appendChild(el);

		console.log("canvas_px = " + canvas_px);
		while (buffer.childNodes.length > 0) {
			page = document.createElement('div');
			page.className = "pagebreak";
			page_n += 1;
			b.appendChild(page);

			add_until_full(page, page, buffer, canvas_px);

			if (page.offsetHeight > canvas_px)
				trim_page(buffer, page, canvas_px);

			console.log("page " + page_n + ": " + page.offsetHeight);
		}
	};


	return _paginate;
})();
