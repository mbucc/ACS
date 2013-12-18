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

	function is_a(tag, el) {
		return el && el.nodeName.toUpperCase() == tag.toUpperCase();
	}

	function is_header(el)     { return is_a('header'    , el); }
	function is_break(el)      { return is_a('br'        , el); }
	function is_blockquote(el) { return is_a('blockquote', el); }
	function is_paragraph(el)  { return is_a('p'         , el); }
	function is_form(el)       { return is_a('form'      , el); }
	function is_href(el)       { return is_a('a   '      , el); }


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

	// "</b>" for example.
	function is_close_tag(word) {
		return /^<\//.test(word);
	}

	// "<b>" for example.
	function is_open_tag(word) {
		return /^<[^\/]/.test(word);
	}

	// "src='/img/a.png'>" for example
	function is_tag_end(word) {
		return />$/.test(word);
	}

	function parse_tag(word, words) {

		var tag = word;

		while (!is_tag_end(word)) {

			word = words.pop();

			tag = tag + " " + word;
		}

		var i = tag.lastIndexOf(" ");

		tag = tag.substring(0, i);
	}

	// Removes last word from el.innerHTML and returns it.
	function pop_word(el) {

		if (!el)
			return "";

		var s = el.innerHTML;

		if (!s)
			return "";

		var i = s.lastIndexOf(" ");

		el.innerHTML = s.substring(0, i);

		return s.substring(i + 1);

	}
	// Returns last word in el.innerHTML.
	function last_word(el) {

		if (!el)
			return "";

		var s = el.innerHTML;

		if (!s)
			return "";

		var i = s.lastIndexOf(" ");

		return s.substring(i + 1);

	}

	// <b> --> b
	// <a  --> a
	// 	We know the word won't have a trailing space.
	function wordtotag(w) {

		// Throw exception if assumption fails.

		return w.replace(
			/^<([^>]*)>?/
			, function(match, group) {
				return group;
			}
		);

	}

	function close_tag(tag) {

		return "</" + tag + ">";

	}

	function add_close_tags(el, tags) {

		for (var i = tags.length - 1; i >= 0; i--)

			el.innerHTML += " " + close_tag(tags[i]);

	}

	function remove_close_tags(el, tags) {

		for (var i = tags.length - 1; i >= 0; i--)

			pop_word(el);

	}

	// Paragraphs can be long and they don't have child elements.  So we
	// just keep adding words until the page is full.
	function add_words_until_full(page, new_para, para, is_full_px) {

		var
			words = para
				.innerHTML
				.replace(/  */g, ' ')
				.split(' ')
				.reverse()
			, word
			, tags = []
			;

		if (_debug)
			console.log("------ add_words_until_full: " +
				       	words.length + " words, is_full_px = " +
					is_full_px);

		para.innerHTML = '';

		while ((word = words.pop())) {

			if (is_close_tag(word)) {

				word = parse_tag(word, words);

				tags.pop();

			}

			// Paragraph can have <b> or <a href or <i> etc.
			else if (is_open_tag(word)) {

				word = parse_tag(word, words);

				tags.push(word);

			}

			new_para.innerHTML += ' ' + word;

			// I assume the browser needs all tags closed to 
			// be able to calculate the correct height.
			add_close_tags(new_para, tags);

			if (page.offsetHeight >= is_full_px)
				break;

			remove_close_tags(new_para, tags);

			if (_debug)
				console.log("    " + page.offsetHeight + ": " +
					word + " (" +
					(page.offsetHeight >= is_full_px) +
					")"
					);

		}

		if (page.offsetHeight > is_full_px) {

			remove_close_tags(new_para, tags);

			words.push(pop_word(new_para));

			add_close_tags(new_para, tags);

		}

		words.reverse();

		para.innerHTML = words.join(' ');

	}

	function add_until_full(page, parent_el, pool, is_full_px) {

		if (_debug)
			console.log("------ add_until_full: parent = " +
				       	parent_el.nodeName);

		for (
				var el = pool.firstChild;
				el && page.offsetHeight < is_full_px;
				el = pool.firstChild
				)
		{

			parent_el.appendChild(el);

			if (_debug)
				console.log(page.offsetHeight 
						+ ": " + el.nodeName);

		}

		// Adding last element overflowed the page.  Remove it and
		// then try to split it up.
		if (page.offsetHeight >= is_full_px) {

			var el = parent_el.lastChild;

			if (!el) {

				// We are inside, trying to split the initial
				// element that overflowed.  But
				// we weren't able to add even one of
				// the children.  Simply adding the
				// parent node overflowed the page.
				// Remove the parent node, it will all
				// have to go on the next page.

				var grandparent = parent_el.parentElement;

				grandparent.removeChild(parent_el);

				return;
			}

			// Remove last-added element to the page.
			insert(pool, el);

			if (is_form(el) || is_href(el)) {

				// Don't split up forms.
				return;

			}
			else if (is_paragraph(el)) {

				var new_parent = document.createElement("P");

				parent_el.appendChild(new_parent);

				add_words_until_full(
						page
						, new_parent
						, el
						, is_full_px
						);

			}

			else if (el.childNodes.length > 0) {

				var new_parent = document
					.createElement(el.nodeName);

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
			, max_conceivable_pages = 100
			, reveal_center = false
			// default/cube/page/concave/zoom/linear/fade/none
			, reveal_transition = 'linear'
			;

		// Swap out page contents from the <body>.
		for (var el = b.firstChild; el; el = b.firstChild)
			buffer.appendChild(el);

		// Reveal.js wrapper div.
		var reveal = document.createElement('div');
		reveal.className = "reveal " +
			reveal_transition +
			(reveal_center ? " center" : "") ;
		b.appendChild(reveal);

		// Slides wrapper div.
		var slides = document.createElement('div');
		slides.className = "slides";
		reveal.appendChild(slides);

		console.log("canvas_px = " + canvas_px);
		while (buffer.childNodes.length > 0
				&& page_n < max_conceivable_pages)
		{
			// A slide div.
			page = document.createElement('section');
			page_n += 1;
			page.className = (page_n == 1 ? "present" : "future");

			slides.appendChild(page);

			add_until_full(page, page, buffer, canvas_px * slop_factor);

			console.log("page " + page_n + ": " + page.offsetHeight);
		}

		var overfull = false;
		if (page_n >=  max_conceivable_pages) {
			overfull = true;
			// We were not able to fit an element on the page.
			// XXX: Post this condition back to the server.

			// Don't lose content.
			for (var el = buffer.firstChild; el; el = pool.firstChild)
				page.appendChild(el);
		}

		if (!overfull)
			// Full list of configuration options available here:
			// https://github.com/hakimel/reveal.js#configuration
			Reveal.initialize({
				 controls: true
				, progress: false
				, history: false
				, center: reveal_center
				, transition: reveal_transition
			});

	};


	return _paginate;
})();
