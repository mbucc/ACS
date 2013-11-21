
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
	function state_template(name, process_input_fcn) {
		return {name: name, process: process_input_fcn};
	}

	var idle = state_template("idle", function(machine, input) {
		machine.current_state = inpage;
	});

	var inpage = state_template("inpage", function(machine, input) {
		if (!input) {
			machine.finish_page();
			machine.current_state = idle;
		}
		else {
			// All other inputs keep us in the same state name.
			if (machine.pageheight + height(input) > machine.maxheight) {
				machine.finish_page();
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
		var h = 0;
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

	//--------------------------------------------------------------------
	//
	//                     S T A T E   M A C H I N E 
	//
	//--------------------------------------------------------------------

	var state_machine = (function() {

		var 
			maxheight
			, stack = []
			, pageheight = 0
			, current_state
			, buffer = null
			, page = null
			, page_n = 0
			;

		var _init = function(the_maxheight, initial_state) {
			this.maxheight = the_maxheight;
			this.current_state = initial_state;
			this.pageheight = 0;
			page_n = 0;
			stack = []
		};

		var _add = function(el) {
			stack.push(el);
			this.pageheight = this.pageheight + height(el);
		};

		var _new_page = function() {
			page_n = page_n + 1;
			var p = document.createElement('div');
			p.className = "pagebreak";
			return p;
		};

		var _finish_page = function() {
			if (this.buffer == null) {
				this.buffer = document.createElement('div');
				page = _new_page();
			}

			console.log("-------------------- START PAGE "  + page_n);
			console.log("     pageheight: " + this.pageheight);
			console.log("      maxheight: " + this.maxheight);

			this.buffer.appendChild(page);

			var n = stack.length;
			for (var i = 0; i < n; i++) {
				console.log(stack[i].nodeName);
				page.appendChild(stack[i]);
			}
			console.log("-------------------- END   PAGE\n");

			stack = [];
			this.pageheight = 0;

			page = _new_page();
		};

		return {
			init: _init
			, add: _add
			, finish_page: _finish_page
			, current_state: current_state
			, maxheight: maxheight
			, pageheight: pageheight
			, buffer: buffer
		};
	})();

	return {
		state_machine: state_machine
		, height: height
		, IdleState: idle
	};
})();
