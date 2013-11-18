// State Machine that handles pagination.
// Created on Thu Nov 14 20:05:35 EST 2013
// by Mark Bucciarelli <mkbucc@gmail.com>
"use strict";
var pagination = (function () {

	//--------------------------------------------------------------------
	//
        //                       S T A T E S 
	// 
	//--------------------------------------------------------------------
	
	// process_input_function = function(machine, input);
	function state(name, process_input_fcn) {
		this.name = name;
		this.process = process_input_fcn;
	}

	var idle = state("idle", function(machine, input) {
		state.current = inpage;
	});

	var inpage = state("inpage", function(machine, input) {
		if (!input) {
			machine.state = idle;
		}
		else {
			// All other inputs keep us in the same state name.
			if (machine.height + height(input) > machine.size) {
				machine.add_break();
			}
			machine.add(input);
		}
	});

	//--------------------------------------------------------------------
	//
        //                            U T I L S 
	//
	//--------------------------------------------------------------------

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

	function topmargin(el) {
		return pxtoi(getStyle(el, "margin-top"));
	};

	function bottommargin(el) {
		return pxtoi(getStyle(el, "margin-bottom"));
	};

	// getBoundingClientRect() does not include margins and in  
	// CSS, overlapping margins collapse, so we hack the element
	// height using just the top margin.
	//   http://andybudd.com/archives/2003/11/no_margin_for_error/
	//   http://reference.sitepoint.com/css/collapsingmargins
	function height(el) {
		return el.getBoundingClientRect().height + topmargin(el);
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

	//--------------------------------------------------------------------
	//
        //                     S T A T E   M A C H I N E 
	//
	// Usage example:
	//
	//	var page_height_px = 500;
	// 	m = state_machine(page_height_px);
	// 	el = document.body.firstElementChild;
	// 	while (el)
	// 		m.state.process(el);
	// 	this.body.innerHtml = m.state.body.innerHtml;
	//--------------------------------------------------------------------

	function state_machine(the_maxheight) {
		this.stack = [];
		this.pageheight = 0;
		this.maxheight = the_maxheight;
		this.state = idle;
		this.dump_fnc = page_dump_fcn;
		this.body = null;
		this.page = null;
		this.page_n = 0;

		function add(el) {
			stack.push(el);
			pageheight = pageheight + height(el)
		}

		function newpage() {
			this.page_n = this.page_n + 1;
			var p = document.createElement('div');
			p.className = "pagebreak";
			return p;
		}

		function add_break() {
			if (body == null) {
				body = document.createElement('div');
				page = newpage();
			}

			console.log("-------------------- START PAGE "  +
				this.page_n);

			body.appendChild(page);

			var n = stack.length;
			for (var i = 0; i < n; i++) {
				console.log(stack[i].nodeName);
				page.appendChild(stack[i]);
			}
			console.log("-------------------- END   PAGE\n");

			stack = [];
			pageheight = 0;

			page = newpage();
		}
	}

	return {
		state_machine: state_machine
		, height: height
	};
})();
