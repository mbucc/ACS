// Dynamically paginate body for reveal.js navigation.
// Created on Thu Nov 14 20:05:35 EST 2013
// by Mark Bucciarelli <mkbucc@gmail.com>
"use strict";

var paginate = (function () {

	var
		_debug = true
		, page_full_slop_percentage = 5
		, slop_factor = (1 - page_full_slop_percentage/100.)
		;

	// Return true if the element is a heading.
	function is_heading(el) {
		return el && /H[1-6]/.test(el.nodeName);
	};

	// Return true if the element is a header tag.
	function is_header(el) {
		return el && el.nodeName.toUpperCase() == "HEADER";
	};

	function is_break(el) {
		return el && el.nodeName.toUpperCase() == "BR";
	};

	function is_blockquote(el) {
		return el && el.nodeName.toUpperCase() == "BLOCKQUOTE";
	};

	function is_paragraph(el) {
		return el && el.nodeName.toUpperCase() == "P";
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

	// Paragraphs can be long and they don't have child elements.  So we
	// just keep adding words until the page is full.
	function add_words_until_full(page, new_paragraph, paragraph, is_full_px) {

		var
			words = paragraph
				.innerHTML
				.replace(/  */g, ' ')
				.split(' ')
				.reverse()
			, word
			;

		if (_debug)
			console.log("------ add_words_until_full: " +
				       	words.length + " words, is_full_px = " +
					is_full_px);

		paragraph.innerHTML = '';

		while ((word = words.pop())) {

			new_paragraph.innerHTML += ' ' + word;

			if (page.offsetHeight >= is_full_px)
				break;

			if (_debug)
				console.log("    " + page.offsetHeight + ": " +
						word + " (" +
						(page.offsetHeight >= is_full_px) +
						")"
						);
		}

		if (page.offsetHeight > is_full_px) {

			words.push(word);

			var s = new_paragraph.innerHTML;

			var i = s.lastIndexOf(" ");

			new_paragraph.innerHTML = s.substring(0, i);

		}

		words.reverse();

		paragraph.innerHTML = words.join(' ');

	}

	function add_until_full(page, parent_el, el_pool, is_full_px) {

		if (_debug)
			console.log("------ add_until_full: parent = " +
				       	parent_el.nodeName);

		for (
				var el = el_pool.firstChild;
				el && page.offsetHeight < is_full_px;
				el = el_pool.firstChild
				)
		{

			parent_el.appendChild(el);

			if (_debug)
				console.log(page.offsetHeight + ": " + el.nodeName);

		}

		if (page.offsetHeight >= is_full_px) {

			var el = parent_el.lastChild;

			if (!el) {

				// We could not add any children to the new
				// parent node, so remove the new parent node.

				var grandparent = parent_el.parentElement;

				grandparent.removeChild(parent_el);

				return;
			}

			insert(el_pool, el);


			if (is_paragraph(el)) {

				var new_parent = document.createElement("P");

				parent_el.appendChild(new_parent);

				add_words_until_full(page, new_parent, el, is_full_px);

			}

			else if (el.childNodes.length > 0) {

				var new_parent = document.createElement(el.nodeName);

				parent_el.appendChild(new_parent);

				add_until_full(page, new_parent, el, is_full_px);

			}

			else
				; // leave element off page.

		}
	}


	function _paginate() {

		var
			  b = document.body
			, canvas_px = canvasheight()
			, page_n = 0
			, buffer = document.createElement('div')
			, page = null
			, max_pages_conceivable = 100
			, reveal_center = false
			, reveal_transition = 'linear'
			;

		// Move page contents from <body> to a buffer.
		for (var el = b.firstChild; el; el = b.firstChild)
			buffer.appendChild(el);

		var reveal = document.createElement('div');
		reveal.className = "reveal " +
			reveal_transition +
			(reveal_center ? " center" : "") ;
		b.appendChild(reveal);

		var slides = document.createElement('div');
		slides.className = "slides";
		reveal.appendChild(slides);

		console.log("canvas_px = " + canvas_px);
		while (buffer.childNodes.length > 0
				&& page_n < max_pages_conceivable)
		{
			page = document.createElement('section');
			page_n += 1;
			page.className = (page_n == 1 ? "present" : "future");

			slides.appendChild(page);

			add_until_full(page, page, buffer, canvas_px * slop_factor);

			console.log("page " + page_n + ": " + page.offsetHeight);
		}

		if (page_n >=  max_pages_conceivable)
			// XXX: Post this error back to the server.
			;

		// Full list of configuration options available here:
		// https://github.com/hakimel/reveal.js#configuration
		Reveal.initialize({
			controls: true,
			progress: false,
			history: true,
			center: reveal_center,

			// available themes are in /css/theme
			theme: Reveal.getQueryHash().theme,

			// default/cube/page/concave/zoom/linear/fade/none
			transition: Reveal.getQueryHash().transition || reveal_transition,

			// Parallax scrolling
			// parallaxBackgroundImage: 'https://s3.amazonaws.com/hakim-static/reveal-js/reveal-parallax-1.jpg',
			// parallaxBackgroundSize: '2100px 900px',

			// Optional libraries used to extend on reveal.js
			dependencies: []
		});

	};


	return _paginate;
})();
