/*jslint vars: true, white: true */
/*global jQuery */

var VISKOSITY = VISKOSITY || {};

(function($, ns) {

"use strict";

if(!Object.create) {
	Object.create = function(obj) {
		if(arguments.length > 1) {
			throw new Error("properties parameter is not supported");
		}
		var F = function() {};
		F.prototype = obj;
		return new F();
	};
}

ns.cappedStack = function(maxItems) {
	var arr = [];
	return {
		push: function(item) {
			arr.push(item);
			if(arr.length > maxItems) {
				arr.shift();
			}
		},
		pop: function() { return arr.pop(); }
	};
};

ns.setContext = function(fn, ctx) {
	return function() {
		var context = $.extend({ context: this }, ctx);
		fn.apply(context, arguments);
	};
};

// convenience wrapper
// returns a property getter for arbitrary objects
// if multiple arguments are supplied, the respective sub-property is returned
ns.getProp = function() { // TODO: memoize
	var args = arguments;
	return function(obj) {
		var res = obj;
		$.each(args, function(i, prop) { // TODO: use `reduce`
			res = res[prop];
		});
		return res;
	};
};

// convenience wrapper for jQuery#each callbacks
// returns a function which appends the given item to the specified array
ns.pusher = function(arr) {
	return function(i, item) {
		arr.push(item);
	};
};

// remove elements from array
ns.evict = function(items, arr) { // XXX: inefficient!?
	var i;
	for(i = arr.length - 1; i >= 0; i--) {
		if($.inArray(arr[i], items) !== -1) {
			arr.splice(i, 1);
		}
	}
};

}(jQuery, VISKOSITY));
