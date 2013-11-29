// State Machine that handles pagination.
// Created on Thu Nov 14 20:05:35 EST 2013
// by Mark Bucciarelli <mkbucc@gmail.com>
"use strict";


var pagination = (function () {

	var
		_stack = []
		, _maxheight
		, _pageheight
		, _page_n = 0
		, _buffer
		, _current_state
		, _page

		// Don't make a header the last line on a page.
		, _section_buffer_size
		, _start_section_height

		// Dump lots of stuff to console.
		, _debug = true
		;

	//--------------------------------------------------------------------
	//
        //                       S T A T E S
	//
	//--------------------------------------------------------------------
	//

	function _changeto(newstate) {
		if (_debug)
			console.log("_changeto(" + newstate.name + ")");
		_current_state = newstate;
	}

	function state_template(name, process_input_fcn) {
		return {name: name, process: process_input_fcn};
	}

	var _idle = state_template("idle", function(machine, input) {
		_changeto(_inpage);
		_add(input);
		return input.nextSibling;
	});

	var _inpage = state_template("inpage", function(machine, input) {
		if (!input) {
			_changeto(_idle);
			return null;
		}
		else if (is_heading(input)) {
			_changeto(in_recently_started_page_section);
			_start_section();
			return _current_state.process(machine, input);
		}
		else {
			// All other inputs keep us in the same state name.
			if (fullpage(machine, input))
				_finish_page();
			_add(input);
			return input.nextSibling;
		}
	});

	var in_recently_started_page_section = state_template(
		"in_recently_started_page_section"
		, function(machine, input)
	{
		if (!input) {
			_changeto(_idle);
			return null;
		}
		else {
			if (_section_no_longer_recent()) {
				_changeto(_inpage);
				if (fullpage(machine, input))
					_finish_page();
			}
			else {
				if (fullpage(machine, input)) {
					var s = split_on_header(_stack);
					_finish_page();
					_stack = s;
				}
			}
			_add(input);
			return input.nextSibling;
		}
	});

	//--------------------------------------------------------------------
	//
        //                            U T I L S
	//
	//--------------------------------------------------------------------

	// Split stack on last header tag.  Return bit you break off.
	function split_on_header(stack) {
		var
			n = stack.length
			, found = -1
			, rval = []
			;

		for (var i = n - 1; i >= 0 && found == -1; i--) {
			if (is_heading(stack[i]))
				found = i;
		}

		for (var i = found; i < n; i++)
			rval[found - i] = stack.splice(found, 1);

		return rval;
	}

	// Return truthy if node is a header node.
	function is_heading(input) {
		return input && /H[1-6]/.test(input.nodeName);
	}

	function is_header(input) {
		return input && input.nodeName == "HEADER";
	}
	// Return truthy if node is a break node.
	function is_break(input) {
		return input && input.nodeName == "BR";
	}

	// Return truthy if node is a break node.
	function is_blockquote(input) {
		return input && input.nodeName == "BLOCKQUOTE";
	}
	// Return true if input won't fit in current page.
	function fullpage(machine, input) {
		return _pageheight + height(input) > _maxheight;
	}

	// Return the value of the style for the given element.
	// For example,
	//
	// 	> acs.getStyle(document.body, "margin-top")
	// 	"20px"
	//
	function getStyle(el, stylename) {

		var y = null;

		// Text nodes don't support getComputedStyle.
		if (el.nodeType == Node.TEXT_NODE)
			return y;

		if (el.currentStyle)
			y = el.currentStyle[stylename];
		else if (window.getComputedStyle) {
			var style = window.getComputedStyle(el, null);
			if (style) {
				y = style.getPropertyValue(stylename);
			}
		}
		return y;
	};

	// Convert string to number of pixels.  Be strict about matching, and
	// return zero if no match is found.
	//     "20px" --> 20
	//     "10.03125px" --> 10.03125
	//     "20"   --> 20
	//     "20em" --> 0
	//     "20%"  --> 0
	function pxtoi(val) {
		var
			patterns = [
				  /^\d+.\d+$/i
				, /^\d+\.\d+px$/i
				, /^\d+px$/i
				, /^\d+$/
				]
			, rval = 0
			;
		if (val) {
			for (var i = 0; i < patterns.length && rval == 0; i++)
				if (patterns[i].test(val))
					rval = parseFloat(val);
		}
		return rval;
	};

	// Return an element's top-margin in pixels.
	function topmargin(el) {
		return pxtoi(getStyle(el, "margin-top"));
	};

	// Return an element's bottom-margin in pixels.
	function bottommargin(el) {
		return pxtoi(getStyle(el, "margin-bottom"));
	};

	// getBoundingClientRect() does not include margins and in
	// CSS, overlapping margins collapse, so we hack the element
	// height using just the top margin.
	//   http://andybudd.com/archives/2003/11/no_margin_for_error/
	//   http://reference.sitepoint.com/css/collapsingmargins
	function height(el) {
		var h = 0;
		// Text nodes don't have the getBoundingC... function.
		if (el.nodeType != Node.TEXT_NODE)
			h = el.getBoundingClientRect().height + topmargin(el);
		return h;
	}

	// Returns that element inside the <header> section.
	// For example, getHeader('h2').
	function getHeader(elname) {
		var
			b = document.body
			, header = b.getElementsByTagName('header')[0]
			;
		return header.getElementsByTagName(elname)[0];
	};

	function uncollapsed_bottom_margin(el, stack) {

		// Find last element node.  If none found, return.
		var last = null;
		for (var i = stack.length - 1; i >= 0 && !last; i--)
			if (stack[i].nodeType != Node.TEXT_NODE)
				last = stack[i];
		if (!last)
			return 0;

		// If <BR> follows an item, there is no bottom margin
		// collapsing, so we must count the bottom margin
		// of the previous element.
		// 	Likewise, if blockquote follows the <header>.
		return (
			is_break(el)
			|| (is_blockquote(el) && is_header(last))
			)
				?  bottommargin(last)
				:  0
				;
	};

	//--------------------------------------------------------------------
	//
	//                     S T A T E   M A C H I N E
	//
	//--------------------------------------------------------------------

	function _add(el) {
		_pageheight = _pageheight + height(el) +
		       	uncollapsed_bottom_margin(el, _stack);
		_stack.push(el);
	};

	function _new_page() {
		_page_n = _page_n + 1;
		var p = document.createElement('div');
		p.className = "pagebreak";
		return p;
	};

	function _finish_page() {
		if (_buffer == null) {
			_buffer = document.createElement('div');
			_page = _new_page();
		}

		console.log("----------------- START PAGE "  + _page_n);
		console.log("     pageheight: " + _pageheight);
		console.log("      maxheight: " + _maxheight);

		_buffer.appendChild(_page);

		var n = _stack.length;
		for (var i = 0; i < n; i++) {
			console.log(_stack[i].nodeName);
			_page.appendChild(_stack[i]);
		}
		console.log("----------------- END   PAGE\n");

		_stack = [];
		_pageheight = 0;

		_page = _new_page();
	};

	function _start_section() {
		_start_section_height = _pageheight;
	};

	function _section_height() {
		return _pageheight - _start_section_height;
	};

	function _section_no_longer_recent() {
		var rval = true;
		if (_section_height() > _section_buffer_size) {
			rval = false;
			_start_section_height = 0;
		}
		return rval;
	};

	var _process = function(machine, input) {
		if (_debug) {
			// XXX: Simpler: just measure height of div I'm building?
			// XXX: need to put it on the page (in a hidden div at
			// XXX: the bottom of the page.)
			console.log(_page ? height(_page) : 0);
			var t = _pageheight + height(input) +
				uncollapsed_bottom_margin(input, _stack);
			console.log("_process(m, " + input.nodeName + "): " +
				_pageheight +
				" + " + height(input) +
				" + " + uncollapsed_bottom_margin(input, _stack) +
				" = " + t
				);
		}
		return _current_state.process(machine, input);
	};


	var _state_machine = function(maxheight) {

		_maxheight = maxheight;
		_changeto(_idle);
		_pageheight = 0;
		_stack = []
		_section_buffer_size = Math.min(
			48
			, _maxheight * 0.10 // for small screens
			);

		return {
			  process: _process
			, html: function() {return _buffer.innerHTML;}
			, finish_page: _finish_page
		};
	};

	return {
		state_machine: _state_machine
		, height: height
		, pxtoi: pxtoi
	};
})();
